import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/easy_flow_score_model.dart';
import '../providers/smart_home_provider.dart';
import '../screens/connect_smart_thermostat_page.dart';

class EasyFlowScoreCard extends StatefulWidget {
  final EasyFlowScoreModel? scoreModel;
  final bool isCelsius;
  
  const EasyFlowScoreCard({
    Key? key,
    this.scoreModel,
    this.isCelsius = false,
  }) : super(key: key);

  @override
  State<EasyFlowScoreCard> createState() => _EasyFlowScoreCardState();
}

class _EasyFlowScoreCardState extends State<EasyFlowScoreCard> {

  @override
  Widget build(BuildContext context) {
    // Use provided model or fallback to placeholder
    final model = widget.scoreModel ?? EasyFlowScoreModel.placeholder(isCelsius: widget.isCelsius);
    final score = model.calculateScore();
    final statusMessage = model.getSmartStatusMessage(); // Use smart messaging
    final ventilationHint = model.generateVentilationHint();
    
    return Consumer<SmartHomeProvider>(
      builder: (context, smartHomeProvider, child) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 8,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Stack(
                children: [
                  // Info icon button in top-right corner
                  Positioned(
                    top: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () => _showInfoDialog(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  // Main content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large Score Display
                      _buildScoreDisplay(score),
                      
                      const SizedBox(height: 16),
                      
                      // Dynamic Status Message
                      _buildStatusMessage(statusMessage, score),
                      
                      const SizedBox(height: 20),
                      
                      // Personalized Ventilation Advice
                      _buildVentilationAdvice(ventilationHint, score),
                      
                      const SizedBox(height: 20),
                      
                      // Weather Data Grid
                      _buildWeatherDataGrid(model),
                      
                      const SizedBox(height: 24),
                      
                      // AC Control Section
                      Consumer<SmartHomeProvider>(
                        builder: (context, smartHomeProvider, child) {
                          return _buildACControlSection(context, smartHomeProvider, score);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.eco,
                color: Colors.green[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Easy Flow Score',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'What is the Easy Flow Score?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The Easy Flow Score is an intelligent rating (0-100) that tells you how ideal current conditions are for natural ventilation and fresh air circulation.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'How is it calculated?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildScoreFactorItem(
                  icon: Icons.air,
                  title: 'Wind Speed & Direction',
                  description: 'Optimal wind patterns for effective cross-ventilation',
                  color: Colors.blue[600]!,
                ),
                const SizedBox(height: 12),
                _buildScoreFactorItem(
                  icon: Icons.visibility,
                  title: 'Air Quality',
                  description: 'Clean outdoor air quality for safe ventilation',
                  color: Colors.green[600]!,
                ),
                const SizedBox(height: 12),
                _buildScoreFactorItem(
                  icon: Icons.thermostat,
                  title: 'Temperature',
                  description: 'Comfortable outdoor temperature for natural cooling',
                  color: Colors.orange[600]!,
                ),
                const SizedBox(height: 12),
                _buildScoreFactorItem(
                  icon: Icons.water_drop,
                  title: 'Humidity',
                  description: 'Balanced humidity levels for comfort',
                  color: Colors.cyan[600]!,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Higher scores (70+) indicate excellent conditions for opening windows and enjoying natural ventilation!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green[600],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoreFactorItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay(int score) {
    // Determine score color based on value
    Color scoreColor;
    if (score >= 85) {
      scoreColor = Colors.green[600]!;
    } else if (score >= 70) {
      scoreColor = Colors.lightGreen[600]!;
    } else if (score >= 55) {
      scoreColor = Colors.orange[600]!;
    } else if (score >= 40) {
      scoreColor = Colors.orange[700]!;
    } else {
      scoreColor = Colors.red[600]!;
    }
    
    return Column(
      children: [
        Text(
          '$score / 100',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: scoreColor,
            letterSpacing: -1,
          ),
        ),
        Container(
          height: 4,
          width: 60,
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score / 100,
            child: Container(
              decoration: BoxDecoration(
                color: scoreColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage(String message, int score) {
    Color messageColor;
    if (score >= 70) {
      messageColor = Colors.green[700]!;
    } else if (score >= 40) {
      messageColor = Colors.orange[700]!;
    } else {
      messageColor = Colors.red[700]!;
    }
    
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: messageColor,
        height: 1.3,
      ),
    );
  }

  Widget _buildVentilationAdvice(String advice, int score) {
    // Determine advice container styling based on score
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData adviceIcon;

    if (score >= 70) {
      backgroundColor = Colors.green[50]!;
      borderColor = Colors.green[200]!;
      textColor = Colors.green[800]!;
      adviceIcon = Icons.eco;
    } else if (score >= 40) {
      backgroundColor = Colors.orange[50]!;
      borderColor = Colors.orange[200]!;
      textColor = Colors.orange[800]!;
      adviceIcon = Icons.lightbulb_outline;
    } else {
      backgroundColor = Colors.blue[50]!;
      borderColor = Colors.blue[200]!;
      textColor = Colors.blue[800]!;
      adviceIcon = Icons.info_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            adviceIcon,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              advice,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDataGrid(EasyFlowScoreModel model) {
    return Column(
      children: [
        // First row: Wind direction and speed
        Row(
          children: [
            Expanded(
              child: _buildWeatherDataItem(
                icon: _buildAnimatedWindIcon(),
                label: 'Wind',
                value: '${model.windDirection} ${_formatWindSpeed(model.windSpeed)}',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildWeatherDataItem(
                icon: Icon(
                  Icons.thermostat,
                  color: Colors.black87,
                  size: 24,
                ),
                label: 'Temperature',
                value: '${model.temperature.toStringAsFixed(0)}°${widget.isCelsius ? 'C' : 'F'}',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Second row: Air quality and humidity
        Row(
          children: [
            Expanded(
              child: _buildWeatherDataItem(
                icon: Icon(
                  Icons.air,
                  color: _getAirQualityColor(model.airQualityLevel),
                  size: 24,
                ),
                label: 'Air Quality',
                value: model.airQualityLevel,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildWeatherDataItem(
                icon: Icon(
                  Icons.water_drop,
                  color: Colors.blue[600],
                  size: 24,
                ),
                label: 'Humidity',
                value: '${model.humidity.toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherDataItem({
    required Widget icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedWindIcon() {
    return _buildWindDirectionArrow();
  }

  Widget _buildWindDirectionArrow() {
    final model = widget.scoreModel ?? EasyFlowScoreModel.placeholder(isCelsius: widget.isCelsius);
    final windDirection = model.windDirection;
    final rotationAngle = _getWindDirectionAngle(windDirection);
    
    return Transform.rotate(
      angle: rotationAngle,
      child: Icon(
        Icons.navigation,
        color: Colors.blue[600],
        size: 24,
      ),
    );
  }

  double _getWindDirectionAngle(String direction) {
    // Convert wind direction to rotation angle in radians
    // The arrow points in the direction the wind is blowing TO
    switch (direction.toUpperCase()) {
      case 'N':
        return 0; // North - pointing up
      case 'NNE':
        return math.pi / 8; // 22.5 degrees
      case 'NE':
        return math.pi / 4; // 45 degrees
      case 'ENE':
        return 3 * math.pi / 8; // 67.5 degrees
      case 'E':
        return math.pi / 2; // 90 degrees - pointing right
      case 'ESE':
        return 5 * math.pi / 8; // 112.5 degrees
      case 'SE':
        return 3 * math.pi / 4; // 135 degrees
      case 'SSE':
        return 7 * math.pi / 8; // 157.5 degrees
      case 'S':
        return math.pi; // 180 degrees - pointing down
      case 'SSW':
        return 9 * math.pi / 8; // 202.5 degrees
      case 'SW':
        return 5 * math.pi / 4; // 225 degrees - pointing down-left
      case 'WSW':
        return 11 * math.pi / 8; // 247.5 degrees
      case 'W':
        return 3 * math.pi / 2; // 270 degrees - pointing left
      case 'WNW':
        return 13 * math.pi / 8; // 292.5 degrees
      case 'NW':
        return 7 * math.pi / 4; // 315 degrees
      case 'NNW':
        return 15 * math.pi / 8; // 337.5 degrees
      default:
        return 0; // Default to North
    }
  }

  Color _getAirQualityColor(String airQuality) {
    switch (airQuality.toLowerCase()) {
      case 'good':
        return Colors.green[600]!;
      case 'moderate':
        return Colors.yellow[700]!;
      case 'unhealthy for sensitive groups':
        return Colors.orange[600]!;
      case 'unhealthy':
        return Colors.red[600]!;
      case 'very unhealthy':
        return Colors.purple[600]!;
      case 'hazardous':
        return Colors.red[800]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _formatWindSpeed(double windSpeed) {
    if (widget.isCelsius) {
      // Metric units: wind speed is in m/s, convert to km/h
      final kmh = windSpeed * 3.6;
      return '${kmh.toStringAsFixed(0)} km/h';
    } else {
      // Imperial units: wind speed is already in mph
      return '${windSpeed.toStringAsFixed(0)} mph';
    }
  }

  Widget _buildACControlSection(BuildContext context, SmartHomeProvider smartHomeProvider, int score) {
    // Check if user has connected smart devices
    bool hasConnectedDevices = smartHomeProvider.hasConnectedProviders && smartHomeProvider.hasAvailableDevices;
    
    // Only show AC controls if conditions warrant it or if no devices are connected
    bool shouldShowTurnOnAC = score < 40; // Low score suggests AC might be needed
    bool shouldShowTurnOffAC = score >= 70; // High score suggests windows should be open instead
    
    // Always show connect button when no devices are connected
    if (!hasConnectedDevices) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.thermostat,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Smart Climate Control',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ConnectSmartThermostatPage(),
                  ),
                );
              },
              child: Text(
                'Connect Your Thermostat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      );
    }
    
    // If connected but no AC controls needed, don't show anything
    if (!shouldShowTurnOnAC && !shouldShowTurnOffAC) {
      return const SizedBox.shrink(); // Don't show any AC controls
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.ac_unit,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Smart AC Control',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (shouldShowTurnOnAC) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: smartHomeProvider.isLoading 
                      ? null 
                      : () => _handleTurnOnAC(context, smartHomeProvider),
                    icon: Icon(
                      Icons.power_settings_new,
                      size: 18,
                      color: smartHomeProvider.isLoading ? Colors.grey : Colors.white,
                    ),
                    label: Text(
                      smartHomeProvider.isLoading ? 'Turning On...' : 'Turn On AC',
                      style: TextStyle(
                        color: smartHomeProvider.isLoading ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: smartHomeProvider.isLoading ? Colors.grey[300] : Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              if (shouldShowTurnOffAC) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: smartHomeProvider.isLoading 
                      ? null 
                      : () => _handleTurnOffAC(context, smartHomeProvider),
                    icon: Icon(
                      Icons.power_off,
                      size: 18,
                      color: smartHomeProvider.isLoading ? Colors.grey : Colors.white,
                    ),
                    label: Text(
                      smartHomeProvider.isLoading ? 'Turning Off...' : 'Turn Off AC',
                      style: TextStyle(
                        color: smartHomeProvider.isLoading ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: smartHomeProvider.isLoading ? Colors.grey[300] : Colors.green[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // AC Control Handler Functions
  void _handleTurnOnAC(BuildContext context, SmartHomeProvider smartHomeProvider) async {
    // Check if user has connected devices
    if (!smartHomeProvider.hasConnectedProviders) {
      _showConnectSmartHomeDialog(context, smartHomeProvider);
      return;
    }

    if (!smartHomeProvider.hasAvailableDevices) {
      _showSnackBar(context, 'No AC devices found. Please check your connected devices.', Colors.orange);
      return;
    }

    // Turn on AC
    final success = await smartHomeProvider.turnOnAC();
    
    if (success) {
      _showSnackBar(context, '✅ AC turned on successfully!', Colors.green);
    } else {
      final error = smartHomeProvider.errorMessage ?? 'Failed to turn on AC';
      _showSnackBar(context, '❌ $error', Colors.red);
    }
  }

  void _handleTurnOffAC(BuildContext context, SmartHomeProvider smartHomeProvider) async {
    // Check if user has connected devices
    if (!smartHomeProvider.hasConnectedProviders) {
      _showConnectSmartHomeDialog(context, smartHomeProvider);
      return;
    }

    if (!smartHomeProvider.hasAvailableDevices) {
      _showSnackBar(context, 'No AC devices found. Please check your connected devices.', Colors.orange);
      return;
    }

    // Turn off AC
    final success = await smartHomeProvider.turnOffAC();
    
    if (success) {
      _showSnackBar(context, '✅ AC turned off successfully!', Colors.green);
    } else {
      final error = smartHomeProvider.errorMessage ?? 'Failed to turn off AC';
      _showSnackBar(context, '❌ $error', Colors.red);
    }
  }

  void _showConnectSmartHomeDialog(BuildContext context, SmartHomeProvider smartHomeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect Smart Home'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To control your AC, you need to connect your smart home provider.'),
            SizedBox(height: 12),
            Text('Supported providers:'),
            Text('• SmartThings'),
            Text('• Google Home'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showProviderSelectionDialog(context, smartHomeProvider);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showProviderSelectionDialog(BuildContext context, SmartHomeProvider smartHomeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('SmartThings'),
              subtitle: const Text('Samsung SmartThings Hub'),
              onTap: () {
                Navigator.of(context).pop();
                smartHomeProvider.connectProvider(context, 'smartthings');
                _showSnackBar(context, 'SmartThings connection initiated', Colors.blue);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Google Home'),
              subtitle: const Text('Google Nest devices'),
              onTap: () {
                Navigator.of(context).pop();
                smartHomeProvider.connectProvider(context, 'google');
                _showSnackBar(context, 'Google Home connection initiated', Colors.blue);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
