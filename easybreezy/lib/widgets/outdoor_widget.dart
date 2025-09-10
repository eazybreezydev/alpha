import 'package:flutter/material.dart';

class OutdoorWidget extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  const OutdoorWidget({Key? key, required this.weatherData}) : super(key: key);

  Color _getStatusColor(String type) {
    switch (weatherData[type]['level']) {
      case 'high':
        return Colors.red[500]!;
      case 'medium':
        return Colors.yellow[400]!;
      case 'low':
      default:
        return Colors.green[500]!;
    }
  }

  String _getStatusText(String type) {
  final status = weatherData[type]['status'];
  if (status == null) return '';
  if (status is String) return status;
  if (status is int || status is double) return status.toString();
  return '';
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      {
        'label': 'Air Quality',
        'type': 'airQuality',
        'icon': Icons.air,
        'iconColor': const Color(0xFF90CAF9), // pastel blue
      },
      {
        'label': 'UV',
        'type': 'uv',
        'icon': Icons.wb_sunny,
        'iconColor': const Color(0xFFFFF59D), // pastel yellow
      },
      {
        'label': 'Pollen',
        'type': 'pollen',
        'icon': Icons.local_florist,
        'iconColor': const Color(0xFFF8BBD0), // pastel pink
      },
      {
        'label': 'Bugs',
        'type': 'bugs',
        'icon': Icons.bug_report,
        'iconColor': const Color(0xFFC8E6C9), // pastel green
      },
      {
        'label': 'Health',
        'type': 'health',
        'icon': Icons.favorite,
        'iconColor': const Color(0xFFB3E5FC), // pastel sky
      },
    ];
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Air & Wellness',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(rows.length, (i) => Column(
              children: [
                Row(
                  children: [
                    Icon(
                      rows[i]['icon'] as IconData,
                      color: rows[i]['iconColor'] as Color,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rows[i]['label'] as String,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getStatusColor(rows[i]['type'] as String),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        _getStatusText(rows[i]['type'] as String),
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                if (i < rows.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Divider(
                      color: Colors.grey[200],
                      thickness: 1,
                      height: 1,
                    ),
                  ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
