import 'package:flutter/material.dart';
import '../widgets/wind_forecast_chart.dart';
import '../models/wind_data.dart';

class WindForecastExample extends StatelessWidget {
  const WindForecastExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate sample wind data for the next 6 hours
    final List<WindData> sampleWindData = _generateSampleWindData();
    
    // Define peak wind period (11AM - 2PM)
    final now = DateTime.now();
    final peakStart = DateTime(now.year, now.month, now.day, 11, 0);
    final peakEnd = DateTime(now.year, now.month, now.day, 14, 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wind Forecast Chart Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Example 1: Chart with peak wind highlighting
            WindForecastChart(
              windData: sampleWindData,
              peakStartTime: peakStart,
              peakEndTime: peakEnd,
            ),
            const SizedBox(height: 20),
            
            // Example 2: Chart without peak highlighting
            WindForecastChart(
              windData: sampleWindData,
            ),
            const SizedBox(height: 20),
            
            // Example 3: Empty chart
            const WindForecastChart(
              windData: [],
            ),
          ],
        ),
      ),
    );
  }

  List<WindData> _generateSampleWindData() {
    final now = DateTime.now();
    final List<WindData> windData = [];

    // Generate hourly data for the next 6 hours
    for (int i = 0; i < 6; i++) {
      final timestamp = now.add(Duration(hours: i));
      double speed;
      
      // Simulate varying wind speeds with peak in the middle
      if (i == 0) {
        speed = 12.5;
      } else if (i == 1) {
        speed = 15.2;
      } else if (i == 2) {
        speed = 22.8; // Peak wind
      } else if (i == 3) {
        speed = 25.1; // Peak wind
      } else if (i == 4) {
        speed = 18.7;
      } else {
        speed = 14.3;
      }

      windData.add(WindData(
        timestamp: timestamp,
        speed: speed,
      ));
    }

    return windData;
  }
}
