import 'package:flutter/material.dart';
import '../services/thermostat_control_service.dart';
import '../models/weather_data.dart';

/// Widget that provides smart temperature adjustment suggestions based on weather
class SmartTemperatureSuggestionWidget extends StatefulWidget {
  final WeatherData weatherData;
  final ThermostatStatus? thermostatStatus;
  final String? deviceId;
  final String? accessToken;
  final ThermostatBrand? thermostatBrand;
  final Function(String message)? onSuggestionApplied;

  const SmartTemperatureSuggestionWidget({
    Key? key,
    required this.weatherData,
    this.thermostatStatus,
    this.deviceId,
    this.accessToken,
    this.thermostatBrand,
    this.onSuggestionApplied,
  }) : super(key: key);

  @override
  State<SmartTemperatureSuggestionWidget> createState() => _SmartTemperatureSuggestionWidgetState();
}

class _SmartTemperatureSuggestionWidgetState extends State<SmartTemperatureSuggestionWidget> {
  final ThermostatControlService _thermostatService = ThermostatControlService();
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    if (widget.thermostatStatus == null || !widget.thermostatStatus!.isOnline) {
      return const SizedBox.shrink();
    }

    final suggestions = _generateSmartSuggestions();
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'Smart Temperature Suggestions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...suggestions.map((suggestion) => _buildSuggestionCard(suggestion)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(TemperatureSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: suggestion.priority == SuggestionPriority.high 
            ? Colors.green.shade50 
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: suggestion.priority == SuggestionPriority.high 
              ? Colors.green.shade200 
              : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(suggestion.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      suggestion.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (suggestion.priority == SuggestionPriority.high)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'HIGH SAVINGS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Current vs Suggested Temperature
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTempDisplay(
                'Current',
                suggestion.currentTemp,
                Colors.grey.shade600,
              ),
              Icon(Icons.arrow_forward, color: Colors.grey.shade400),
              _buildTempDisplay(
                'Suggested',
                suggestion.suggestedTemp,
                suggestion.priority == SuggestionPriority.high 
                    ? Colors.green.shade600 
                    : Colors.blue.shade600,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Benefits
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBenefitStat(
                  '${suggestion.estimatedSavings.toStringAsFixed(0)}%',
                  'Energy Saved',
                  Icons.energy_savings_leaf,
                ),
                _buildBenefitStat(
                  '\$${suggestion.costSavings.toStringAsFixed(0)}',
                  'Monthly Savings',
                  Icons.attach_money,
                ),
                _buildBenefitStat(
                  '${suggestion.carbonReduction.toStringAsFixed(1)} kg',
                  'CO₂ Reduced',
                  Icons.eco,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTemperatureAdjustmentDialog(suggestion),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Customize'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isApplying ? null : () => _applySuggestion(suggestion),
                  icon: _isApplying 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(_isApplying ? 'Applying...' : 'Apply Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: suggestion.priority == SuggestionPriority.high 
                        ? Colors.green.shade600 
                        : Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempDisplay(String label, double temp, Color color) {
    return Column(
      children: [
        Text(
          '${temp.toStringAsFixed(0)}°F',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.green.shade600),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<TemperatureSuggestion> _generateSmartSuggestions() {
    final suggestions = <TemperatureSuggestion>[];
    final currentTemp = widget.thermostatStatus!.currentTemp;
    final outsideTemp = widget.weatherData.temperature;
    final humidity = widget.weatherData.humidity;
    final windSpeed = widget.weatherData.windSpeed;
    
    // Cool outside air suggestion
    if (outsideTemp < currentTemp - 5 && windSpeed > 3) {
      final suggestedTemp = widget.thermostatStatus!.targetCoolTemp + 3;
      suggestions.add(TemperatureSuggestion(
        icon: '🌬️',
        title: 'Cool Outside Air Available',
        description: 'Outside is ${outsideTemp.toStringAsFixed(0)}°F with good breeze. Consider opening windows and raising AC.',
        currentTemp: widget.thermostatStatus!.targetCoolTemp,
        suggestedTemp: suggestedTemp,
        estimatedSavings: 25.0,
        costSavings: 15.0,
        carbonReduction: 2.8,
        priority: SuggestionPriority.high,
        reason: SuggestionReason.naturalCooling,
        duration: const Duration(hours: 4),
      ));
    }

    // Pre-cooling suggestion
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour <= 10 && outsideTemp > 85) {
      final suggestedTemp = widget.thermostatStatus!.targetCoolTemp - 2;
      suggestions.add(TemperatureSuggestion(
        icon: '❄️',
        title: 'Pre-Cool for Hot Day',
        description: 'Cool down now before peak heat (${outsideTemp.toStringAsFixed(0)}°F forecast). Lower AC temporarily.',
        currentTemp: widget.thermostatStatus!.targetCoolTemp,
        suggestedTemp: suggestedTemp,
        estimatedSavings: 18.0,
        costSavings: 12.0,
        carbonReduction: 2.1,
        priority: SuggestionPriority.high,
        reason: SuggestionReason.preCooling,
        duration: const Duration(hours: 3),
      ));
    }

    // High humidity adjustment
    if (humidity > 70) {
      final suggestedTemp = widget.thermostatStatus!.targetCoolTemp - 1;
      suggestions.add(TemperatureSuggestion(
        icon: '💧',
        title: 'Dehumidify for Comfort',
        description: 'High humidity (${humidity.toStringAsFixed(0)}%). Lower temp slightly to improve comfort.',
        currentTemp: widget.thermostatStatus!.targetCoolTemp,
        suggestedTemp: suggestedTemp,
        estimatedSavings: 8.0,
        costSavings: 5.0,
        carbonReduction: 0.9,
        priority: SuggestionPriority.medium,
        reason: SuggestionReason.humidity,
        duration: const Duration(hours: 2),
      ));
    }

    // Mild weather optimization
    if (outsideTemp >= 68 && outsideTemp <= 78) {
      final suggestedTemp = widget.thermostatStatus!.targetCoolTemp + 2;
      suggestions.add(TemperatureSuggestion(
        icon: '🌤️',
        title: 'Perfect Weather Day',
        description: 'Mild ${outsideTemp.toStringAsFixed(0)}°F outside. Raise AC temp and save energy.',
        currentTemp: widget.thermostatStatus!.targetCoolTemp,
        suggestedTemp: suggestedTemp,
        estimatedSavings: 20.0,
        costSavings: 18.0,
        carbonReduction: 3.2,
        priority: SuggestionPriority.high,
        reason: SuggestionReason.mildWeather,
        duration: const Duration(hours: 6),
      ));
    }

    return suggestions;
  }

  Future<void> _applySuggestion(TemperatureSuggestion suggestion) async {
    if (widget.deviceId == null || widget.accessToken == null || widget.thermostatBrand == null) {
      _showErrorDialog('Thermostat not properly connected');
      return;
    }

    setState(() => _isApplying = true);

    try {
      final success = await _thermostatService.setTemperature(
        deviceId: widget.deviceId!,
        accessToken: widget.accessToken!,
        targetTemp: suggestion.suggestedTemp,
        brand: widget.thermostatBrand!,
        mode: TemperatureMode.cooling,
        holdDuration: suggestion.duration,
      );

      if (success) {
        widget.onSuggestionApplied?.call(
          '${suggestion.title} applied! Temperature set to ${suggestion.suggestedTemp.toStringAsFixed(0)}°F'
        );
        
        // Show success dialog with benefits
        _showSuccessDialog(suggestion);
      } else {
        _showErrorDialog('Failed to apply temperature setting');
      }
    } catch (e) {
      _showErrorDialog('Error applying suggestion: $e');
    } finally {
      setState(() => _isApplying = false);
    }
  }

  void _showTemperatureAdjustmentDialog(TemperatureSuggestion suggestion) {
    double customTemp = suggestion.suggestedTemp;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Customize ${suggestion.title}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(suggestion.description),
              const SizedBox(height: 16),
              Text('Target Temperature: ${customTemp.toStringAsFixed(0)}°F'),
              Slider(
                value: customTemp,
                min: 65,
                max: 80,
                divisions: 15,
                onChanged: (value) => setState(() => customTemp = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applySuggestion(suggestion.copyWith(suggestedTemp: customTemp));
            },
            child: const Text('Apply Custom'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(TemperatureSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Applied Successfully!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Temperature set to ${suggestion.suggestedTemp.toStringAsFixed(0)}°F'),
            const SizedBox(height: 8),
            Text('Expected benefits:'),
            Text('• ${suggestion.estimatedSavings.toStringAsFixed(0)}% energy savings'),
            Text('• \$${suggestion.costSavings.toStringAsFixed(0)} monthly savings'),
            Text('• ${suggestion.carbonReduction.toStringAsFixed(1)} kg CO₂ reduction'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class TemperatureSuggestion {
  final String icon;
  final String title;
  final String description;
  final double currentTemp;
  final double suggestedTemp;
  final double estimatedSavings; // Percentage
  final double costSavings; // Dollars per month
  final double carbonReduction; // kg CO2 per day
  final SuggestionPriority priority;
  final SuggestionReason reason;
  final Duration duration;

  const TemperatureSuggestion({
    required this.icon,
    required this.title,
    required this.description,
    required this.currentTemp,
    required this.suggestedTemp,
    required this.estimatedSavings,
    required this.costSavings,
    required this.carbonReduction,
    required this.priority,
    required this.reason,
    required this.duration,
  });

  TemperatureSuggestion copyWith({
    String? icon,
    String? title,
    String? description,
    double? currentTemp,
    double? suggestedTemp,
    double? estimatedSavings,
    double? costSavings,
    double? carbonReduction,
    SuggestionPriority? priority,
    SuggestionReason? reason,
    Duration? duration,
  }) {
    return TemperatureSuggestion(
      icon: icon ?? this.icon,
      title: title ?? this.title,
      description: description ?? this.description,
      currentTemp: currentTemp ?? this.currentTemp,
      suggestedTemp: suggestedTemp ?? this.suggestedTemp,
      estimatedSavings: estimatedSavings ?? this.estimatedSavings,
      costSavings: costSavings ?? this.costSavings,
      carbonReduction: carbonReduction ?? this.carbonReduction,
      priority: priority ?? this.priority,
      reason: reason ?? this.reason,
      duration: duration ?? this.duration,
    );
  }
}

enum SuggestionPriority { low, medium, high }
enum SuggestionReason { naturalCooling, preCooling, humidity, mildWeather, peakHours }
