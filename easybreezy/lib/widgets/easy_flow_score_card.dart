import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/easy_flow_score_model.dart';

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
              
              const SizedBox(height: 24),
              
              // Weather Data Grid
              _buildWeatherDataGrid(model),
            ],
          ),
        ],
      ),
        ),
      ),
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
}
