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
  return status is String ? status : status.toString();
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      {'label': 'Air Quality', 'type': 'airQuality'},
      {'label': 'UV', 'type': 'uv'},
      {'label': 'Pollen', 'type': 'pollen'},
      {'label': 'Bugs', 'type': 'bugs'},
      {'label': 'Health', 'type': 'health'},
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
                    Expanded(
                      child: Text(
                        rows[i]['label']!,
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
                          color: _getStatusColor(rows[i]['type']!),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        _getStatusText(rows[i]['type']!),
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
