import 'package:flutter/material.dart';
import '../models/home_config.dart';
import '../models/weather_data.dart';
import '../utils/recommendation_engine.dart';

class RecommendationCard extends StatelessWidget {
  final WindowRecommendation recommendation;
  final HomeConfig homeConfig;
  final WeatherData weatherData;

  const RecommendationCard({
    Key? key,
    required this.recommendation,
    required this.homeConfig,
    required this.weatherData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 8,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _getBorderColor(),
            width: 2,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and icon
              Row(
              children: [
                Icon(
                  _getRecommendationIcon(),
                  size: 30,
                  color: _getIconColor(),
                ),
                const SizedBox(width: 12),
                Text(
                  _getRecommendationTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Recommendation text
            Text(
              recommendation.reasonText,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            
            // Window directions to open
            if (recommendation.shouldOpenWindows &&
                recommendation.recommendedWindows.isNotEmpty) ...[
              const Text(
                'Recommended Windows to Open:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildWindowDirectionsRow(),
              const SizedBox(height: 8),
            ],
            
            // Wind info when windows should be open
            if (recommendation.shouldOpenWindows) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.air, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Wind: ${weatherData.windSpeed.toStringAsFixed(1)} mph from the ${_getWindDirectionName(weatherData.windDirection)}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (recommendation.shouldOpenWindows) ...[
                  // Show "Turn off AC" chip when windows should be opened
                  Chip(
                    avatar: const Icon(
                      Icons.power_off,
                      size: 16,
                      color: Colors.green,
                    ),
                    label: const Text('Turn off AC'),
                    backgroundColor: Colors.green.withOpacity(0.1),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      _showWindDirectionInfo(context);
                    },
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('More Info'),
                  ),
                ] else ...[
                  // Show alternative suggestion if windows should remain closed
                  if (recommendation.airConditioningRecommended) ...[
                    Chip(
                      avatar: const Icon(
                        Icons.ac_unit,
                        size: 16,
                        color: Colors.blue,
                      ),
                      label: const Text('AC Recommended'),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                  ] else ...[
                    Chip(
                      avatar: const Icon(
                        Icons.timer,
                        size: 16,
                        color: Colors.orange,
                      ),
                      label: const Text('Check Again Later'),
                      backgroundColor: Colors.orange.withOpacity(0.1),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  IconData _getRecommendationIcon() {
    if (recommendation.shouldOpenWindows) {
      return Icons.window;
    } else if (recommendation.airConditioningRecommended) {
      return Icons.ac_unit;
    } else {
      return Icons.do_not_disturb;
    }
  }

  String _getRecommendationTitle() {
    if (recommendation.shouldOpenWindows) {
      switch (recommendation.type) {
        case RecommendationType.ideal:
          return 'Ideal for Open Windows!';
        case RecommendationType.good:
          return 'Good Time to Open Windows';
        default:
          return 'Consider Opening Windows';
      }
    } else {
      return 'Keep Windows Closed';
    }
  }

  Color _getIconColor() {
    switch (recommendation.type) {
      case RecommendationType.ideal:
        return Colors.green;
      case RecommendationType.good:
        return Colors.lightGreen;
      case RecommendationType.fair:
        return Colors.amber;
      case RecommendationType.poor:
        return Colors.orange;
      case RecommendationType.notRecommended:
        return Colors.red;
    }
  }

  Color _getBorderColor() {
    if (recommendation.shouldOpenWindows) {
      return _getIconColor().withOpacity(0.7);
    } else {
      return Colors.grey;
    }
  }

  String _getWindDirectionName(String shortDirection) {
    // Convert short direction codes like "NE" to full names
    switch (shortDirection) {
      case 'N':
        return 'North';
      case 'NE':
        return 'Northeast';
      case 'E':
        return 'East';
      case 'SE':
        return 'Southeast';
      case 'S':
        return 'South';
      case 'SW':
        return 'Southwest';
      case 'W':
        return 'West';
      case 'NW':
        return 'Northwest';
      default:
        return shortDirection;
    }
  }

  Widget _buildWindowDirectionsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: recommendation.recommendedWindows.map((direction) {
        return Chip(
          avatar: Icon(
            _getDirectionIcon(direction),
            size: 16,
            color: Colors.blue,
          ),
          label: Text(direction.name),
          backgroundColor: Colors.blue.withOpacity(0.1),
        );
      }).toList(),
    );
  }

  IconData _getDirectionIcon(WindowDirection direction) {
    switch (direction) {
      case WindowDirection.north:
        return Icons.arrow_upward;
      case WindowDirection.east:
        return Icons.arrow_forward;
      case WindowDirection.south:
        return Icons.arrow_downward;
      case WindowDirection.west:
        return Icons.arrow_back;
    }
  }

  void _showWindDirectionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wind Direction Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current wind direction: ${_getWindDirectionName(weatherData.windDirection)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Wind speed: ${weatherData.windSpeed.toStringAsFixed(1)} mph',
                ),
                const SizedBox(height: 12),
                const Text(
                  'For optimal airflow, open windows on opposite sides of your home. This creates cross-ventilation that can effectively cool your space.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Windows on the side facing the wind allow air to enter, while windows on the opposite side help it exit.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}