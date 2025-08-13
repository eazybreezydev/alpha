import 'package:flutter/material.dart';

class WindLevelCard extends StatelessWidget {
  final double windSpeed; // Wind speed in m/s (from API)
  final bool isCelsius; // To determine if we need metric conversion

  const WindLevelCard({
    Key? key,
    required this.windSpeed,
    required this.isCelsius,
  }) : super(key: key);

  // Convert wind speed to the appropriate display units
  double get _convertedWindSpeed {
    if (isCelsius) {
      // Metric units: wind speed is in m/s, convert to km/h
      return windSpeed * 3.6;
    } else {
      // Imperial units: wind speed is already in mph
      return windSpeed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final windLevel = _getWindLevel(_convertedWindSpeed);
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Left side - Text content (50%)
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title in small caps
                  Text(
                    'WIND LEVEL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Breeze level
                  Text(
                    windLevel.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Wind speed with proper unit conversion
                  Text(
                    '${_convertedWindSpeed.toStringAsFixed(1)} ${isCelsius ? 'km/h' : 'mph'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            // Right side - Windsock icon (50%)
            Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.center,
                child: Icon(
                  Icons.flag_outlined,
                  size: 80,
                  color: windLevel.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  WindLevel _getWindLevel(double speed) {
    if (speed < 1) {
      return WindLevel('Calm', Colors.grey[400]!);
    } else if (speed <= 5) {
      return WindLevel('Light Air', Colors.blue[300]!);
    } else if (speed <= 11) {
      return WindLevel('Light Breeze', Colors.blue[400]!);
    } else if (speed <= 19) {
      return WindLevel('Gentle Breeze', Colors.blue[500]!);
    } else if (speed <= 28) {
      return WindLevel('Moderate Breeze', Colors.blue[600]!);
    } else if (speed <= 38) {
      return WindLevel('Fresh Breeze', Colors.orange[500]!);
    } else if (speed <= 49) {
      return WindLevel('Strong Breeze', Colors.orange[600]!);
    } else if (speed <= 61) {
      return WindLevel('Near Gale', Colors.red[500]!);
    } else if (speed <= 74) {
      return WindLevel('Gale', Colors.red[600]!);
    } else if (speed <= 88) {
      return WindLevel('Strong Gale', Colors.red[700]!);
    } else if (speed <= 102) {
      return WindLevel('Storm', Colors.red[800]!);
    } else if (speed <= 117) {
      return WindLevel('Violent Storm', Colors.purple[700]!);
    } else {
      return WindLevel('Hurricane', Colors.purple[900]!);
    }
  }
}

class WindLevel {
  final String label;
  final Color color;

  WindLevel(this.label, this.color);
}
