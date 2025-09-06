import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/wind_data.dart';

class WindForecastChart extends StatefulWidget {
  final List<WindData> windData;
  final DateTime? peakStartTime;
  final DateTime? peakEndTime;
  final bool isCelsius;

  const WindForecastChart({
    Key? key,
    required this.windData,
    this.peakStartTime,
    this.peakEndTime,
    this.isCelsius = false, // Default to imperial (mph)
  }) : super(key: key);

  @override
  State<WindForecastChart> createState() => _WindForecastChartState();
}

class _WindForecastChartState extends State<WindForecastChart> {
  int touchedIndex = -1;

  // Convert wind speed based on user preference
  double _convertWindSpeed(double speedKmh) {
    if (widget.isCelsius) {
      return speedKmh; // Keep km/h for metric
    } else {
      return speedKmh * 0.621371; // Convert km/h to mph for imperial
    }
  }

  // Get the appropriate unit string
  String _getWindUnit() {
    return widget.isCelsius ? 'km/h' : 'mph';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.windData.isEmpty) {
      return _buildEmptyCard();
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildChart(),
            if (widget.peakStartTime != null && widget.peakEndTime != null)
              _buildPeakAnnotation(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.air,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'No wind data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'Wind Forecast',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getWindUnit(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 5,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: _getBottomTitles,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 42,
                getTitlesWidget: _getLeftTitles,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          minX: 0,
          maxX: (widget.windData.length - 1).toDouble(),
          minY: 0,
          maxY: _getMaxWindSpeed() + 5,
          lineBarsData: [
            _buildMainLineData(),
            if (widget.peakStartTime != null && widget.peakEndTime != null)
              _buildPeakHighlightData(),
          ].where((data) => data != null).cast<LineChartBarData>().toList(),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.blueAccent,
              tooltipRoundedRadius: 8,
              getTooltipItems: _getTooltipItems,
            ),
            handleBuiltInTouches: true,
            touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
              setState(() {
                if (response != null && response.lineBarSpots != null) {
                  touchedIndex = response.lineBarSpots!.first.spotIndex;
                } else {
                  touchedIndex = -1;
                }
              });
            },
          ),
        ),
      ),
    );
  }

  LineChartBarData _buildMainLineData() {
    return LineChartBarData(
      spots: widget.windData
          .asMap()
          .entries
          .map((entry) => FlSpot(entry.key.toDouble(), _convertWindSpeed(entry.value.speed)))
          .toList(),
      isCurved: true,
      gradient: LinearGradient(
        colors: [
          Colors.blue.withOpacity(0.8),
          Colors.lightBlue.withOpacity(0.8),
        ],
      ),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: index == touchedIndex ? 6 : 4,
            color: index == touchedIndex ? Colors.blue : Colors.white,
            strokeWidth: 2,
            strokeColor: Colors.blue,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.2),
            Colors.blue.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  LineChartBarData? _buildPeakHighlightData() {
    if (widget.peakStartTime == null || widget.peakEndTime == null) {
      return null;
    }

    final peakSpots = <FlSpot>[];
    for (int i = 0; i < widget.windData.length; i++) {
      final data = widget.windData[i];
      if (data.timestamp.isAfter(widget.peakStartTime!) &&
          data.timestamp.isBefore(widget.peakEndTime!)) {
        peakSpots.add(FlSpot(i.toDouble(), _convertWindSpeed(data.speed)));
      }
    }

    if (peakSpots.isEmpty) return null;

    return LineChartBarData(
      spots: peakSpots,
      isCurved: true,
      gradient: LinearGradient(
        colors: [
          Colors.orange.withOpacity(0.8),
          Colors.red.withOpacity(0.8),
        ],
      ),
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 5,
            color: Colors.orange,
            strokeWidth: 2,
            strokeColor: Colors.red,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.3),
            Colors.orange.withOpacity(0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= widget.windData.length) {
      return const Text('');
    }

    final time = widget.windData[index].timestamp;
    final format = DateFormat('ha'); // 9AM, 10AM, etc.
    
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        format.format(time),
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _getLeftTitles(double value, TitleMeta meta) {
    return Text(
      value.toInt().toString(),
      style: const TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }

  List<LineTooltipItem> _getTooltipItems(List<LineBarSpot> touchedSpots) {
    return touchedSpots.map((LineBarSpot touchedSpot) {
      const textStyle = TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      );

      final index = touchedSpot.spotIndex;
      final windData = widget.windData[index];
      final timeFormat = DateFormat('h:mm a');
      
      return LineTooltipItem(
        '${timeFormat.format(windData.timestamp)}\n${_convertWindSpeed(windData.speed).toStringAsFixed(1)} ${_getWindUnit()}',
        textStyle,
      );
    }).toList();
  }

  Widget _buildPeakAnnotation() {
    final startFormat = DateFormat('ha');
    final endFormat = DateFormat('ha');
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Peak wind expected: ${startFormat.format(widget.peakStartTime!)} - ${endFormat.format(widget.peakEndTime!)}',
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxWindSpeed() {
    if (widget.windData.isEmpty) return 20;
    final maxSpeed = widget.windData
        .map((data) => data.speed)
        .reduce((a, b) => a > b ? a : b);
    return _convertWindSpeed(maxSpeed);
  }
}
