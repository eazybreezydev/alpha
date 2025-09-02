import 'package:flutter/material.dart';
import 'dart:math' as math;

class ThermostatControlCard extends StatefulWidget {
  final String thermostatName;
  final double currentTemperature;
  final double targetTemperature;
  final ThermostatMode currentMode;
  final Function(double)? onTargetTemperatureChanged;
  final Function(ThermostatMode)? onModeChanged;

  const ThermostatControlCard({
    Key? key,
    this.thermostatName = 'Living Room Thermostat',
    this.currentTemperature = 72.0,
    this.targetTemperature = 70.0,
    this.currentMode = ThermostatMode.cooling,
    this.onTargetTemperatureChanged,
    this.onModeChanged,
  }) : super(key: key);

  @override
  State<ThermostatControlCard> createState() => _ThermostatControlCardState();
}

class _ThermostatControlCardState extends State<ThermostatControlCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  double _targetTemp = 70.0;
  ThermostatMode _currentMode = ThermostatMode.cooling;

  @override
  void initState() {
    super.initState();
    _targetTemp = widget.targetTemperature;
    _currentMode = widget.currentMode;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getModeColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.thermostat,
                              color: _getModeColor(),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.thermostatName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _currentMode == ThermostatMode.off 
                                  ? Colors.grey.shade200 
                                  : _getModeColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _currentMode.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _currentMode == ThermostatMode.off 
                                    ? Colors.grey.shade600 
                                    : _getModeColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Temperature Display and Circular Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Current Temperature Display
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.currentTemperature.toStringAsFixed(0)}°',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: _getModeColor(),
                                  ),
                                ),
                                Text(
                                  'Current Temperature',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Target: ${_targetTemp.toStringAsFixed(0)}° • ${_currentMode.displayName}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Circular Slider
                          SizedBox(
                            height: 180,
                            width: 180,
                            child: _buildCircularSlider(),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Mode Control Buttons
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode Controls',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildModeButton(
                                  ThermostatMode.cooling,
                                  Icons.ac_unit,
                                  'Cool',
                                ),
                                _buildModeButton(
                                  ThermostatMode.heating,
                                  Icons.whatshot,
                                  'Heat',
                                ),
                                _buildModeButton(
                                  ThermostatMode.eco,
                                  Icons.energy_savings_leaf,
                                  'Eco',
                                ),
                                _buildModeButton(
                                  ThermostatMode.off,
                                  Icons.power_settings_new,
                                  'Off',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircularSlider() {
    return GestureDetector(
      onPanUpdate: (details) {
        if (_currentMode == ThermostatMode.off) return;
        
        final center = Offset(90, 90); // Half of 180x180
        final delta = details.localPosition - center;
        final angle = math.atan2(delta.dy, delta.dx);
        
        // Convert angle to temperature (60-80°F range)
        // Rotate right for hot, left for cold
        double normalizedAngle = (angle + math.pi) / (2 * math.pi);
        if (normalizedAngle > 0.75) normalizedAngle -= 1.0; // Handle wrap around
        
        // Map to temperature range (inverted so right = hot, left = cold)
        double newTemp = 60 + (1.0 - normalizedAngle) * 20;
        newTemp = newTemp.clamp(60.0, 80.0);
        
        setState(() {
          _targetTemp = newTemp.roundToDouble();
        });
        
        // TODO: Make API call to update thermostat target temperature
        // Example for Nest API:
        // await nestApi.setTargetTemperature(deviceId, _targetTemp);
        // Example for Ecobee API:
        // await ecobeeApi.setHoldTemperature(thermostatId, _targetTemp);
        
        widget.onTargetTemperatureChanged?.call(_targetTemp);
      },
      child: CustomPaint(
        painter: CircularSliderPainter(
          targetTemperature: _targetTemp,
          mode: _currentMode,
          modeColor: _getModeColor(),
        ),
        size: const Size(180, 180),
      ),
    );
  }

  Widget _buildModeButton(ThermostatMode mode, IconData icon, String label) {
    final isSelected = _currentMode == mode;
    final modeColor = _getModeColorForMode(mode);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMode = mode;
        });
        
        // TODO: Make API call to change thermostat mode
        // Example for Nest API:
        // await nestApi.setThermostatMode(deviceId, mode.apiValue);
        // Example for Ecobee API:
        // await ecobeeApi.setHvacMode(thermostatId, mode.apiValue);
        
        widget.onModeChanged?.call(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? modeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? modeColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? modeColor : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? modeColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getModeColor() {
    return _getModeColorForMode(_currentMode);
  }

  Color _getModeColorForMode(ThermostatMode mode) {
    switch (mode) {
      case ThermostatMode.cooling:
        return Colors.blue.shade600;
      case ThermostatMode.heating:
        return Colors.red.shade600;
      case ThermostatMode.eco:
        return Colors.green.shade600;
      case ThermostatMode.off:
        return Colors.grey.shade600;
    }
  }
}

class CircularSliderPainter extends CustomPainter {
  final double targetTemperature;
  final ThermostatMode mode;
  final Color modeColor;

  CircularSliderPainter({
    required this.targetTemperature,
    required this.mode,
    required this.modeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    
    canvas.drawCircle(center, radius, backgroundPaint);

    if (mode != ThermostatMode.off) {
      // Progress arc
      final progressPaint = Paint()
        ..color = modeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      // Calculate angle based on temperature (60-80°F -> 0-2π)
      final tempProgress = (targetTemperature - 60) / 20;
      final sweepAngle = tempProgress * 2 * math.pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );

      // Thumb indicator
      final thumbAngle = -math.pi / 2 + sweepAngle;
      final thumbX = center.dx + radius * math.cos(thumbAngle);
      final thumbY = center.dy + radius * math.sin(thumbAngle);

      final thumbPaint = Paint()
        ..color = modeColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(thumbX, thumbY), 12, thumbPaint);

      // Thumb border
      final thumbBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(thumbX, thumbY), 8, thumbBorderPaint);
    }

    // Center temperature display
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${targetTemperature.toStringAsFixed(0)}°',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: mode == ThermostatMode.off ? Colors.grey.shade400 : modeColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(CircularSliderPainter oldDelegate) {
    return oldDelegate.targetTemperature != targetTemperature ||
           oldDelegate.mode != mode ||
           oldDelegate.modeColor != modeColor;
  }
}

enum ThermostatMode {
  cooling,
  heating,
  eco,
  off;

  String get displayName {
    switch (this) {
      case ThermostatMode.cooling:
        return 'Cooling';
      case ThermostatMode.heating:
        return 'Heating';
      case ThermostatMode.eco:
        return 'Eco';
      case ThermostatMode.off:
        return 'Off';
    }
  }

  // TODO: Add API values for different thermostat brands
  String get apiValue {
    switch (this) {
      case ThermostatMode.cooling:
        return 'cool'; // Nest: 'COOL', Ecobee: 'cool'
      case ThermostatMode.heating:
        return 'heat'; // Nest: 'HEAT', Ecobee: 'heat'
      case ThermostatMode.eco:
        return 'eco'; // Nest: 'ECO', Ecobee: 'auto' with eco settings
      case ThermostatMode.off:
        return 'off'; // Nest: 'OFF', Ecobee: 'off'
    }
  }
}
