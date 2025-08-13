import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

class WindOrientationWidget extends StatelessWidget {
  final String windDirection; // e.g. 'NE'
  final double windSpeed; // e.g. 12.0
  final String userFacingDirection; // e.g. 'NW'
  final double temperature; // e.g. 22.0
  final int humidity; // e.g. 55
  final String aqiLevel; // e.g. 'Good'

  const WindOrientationWidget({
    Key? key,
    required this.windDirection,
    required this.windSpeed,
    required this.userFacingDirection,
    required this.temperature,
    required this.humidity,
    required this.aqiLevel,
  }) : super(key: key);

  String get breezeDescription {
    if (windSpeed < 5) return 'calm';
    if (windSpeed < 15) return 'light breeze';
    if (windSpeed < 25) return 'moderate wind';
    return 'strong wind';
  }

  String get windArrow {
    switch (windDirection) {
      case 'N':
        return '↑';
      case 'NE':
        return '↖';
      case 'E':
        return '←';
      case 'SE':
        return '↙';
      case 'S':
        return '↓';
      case 'SW':
        return '↘';
      case 'W':
        return '→';
      case 'NW':
        return '↗';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = Theme.of(context).cardColor;
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Facing $userFacingDirection – $breezeDescription incoming from $windDirection ($windArrow)',
            style: TextStyle(
              color: primary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          // Enhanced animated compass visualization
          SizedBox(
            height: 64,
            width: 64,
            child: AnimatedCompassArrow(
              direction: windDirection,
              windSpeed: windSpeed,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _EnvStat(
                icon: Icons.thermostat,
                label: '${temperature.toStringAsFixed(0)}°C',
                color: primary,
              ),
              _EnvStat(
                icon: Icons.water_drop,
                label: '$humidity%',
                color: Colors.blueAccent,
              ),
              _EnvStat(
                icon: Icons.eco,
                label: aqiLevel,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnvStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _EnvStat({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class AnimatedCompassArrow extends StatefulWidget {
  final String direction;
  final double windSpeed;
  const AnimatedCompassArrow({Key? key, required this.direction, required this.windSpeed}) : super(key: key);

  @override
  State<AnimatedCompassArrow> createState() => _AnimatedCompassArrowState();
}

class _AnimatedCompassArrowState extends State<AnimatedCompassArrow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _oldDirection = '';

  @override
  void initState() {
    super.initState();
    _oldDirection = widget.direction;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedCompassArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.direction != widget.direction) {
      _controller.forward(from: 0);
      _oldDirection = oldWidget.direction;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _directionToAngle(String dir) {
    switch (dir) {
      case 'N': return -1.5708;
      case 'NE': return -0.7854;
      case 'E': return 0;
      case 'SE': return 0.7854;
      case 'S': return 1.5708;
      case 'SW': return 2.3562;
      case 'W': return 3.1416;
      case 'NW': return -2.3562;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final blur = widget.windSpeed < 5;
    final faded = widget.windSpeed < 5;
    final oldAngle = _directionToAngle(_oldDirection);
    final newAngle = _directionToAngle(widget.direction);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = oldAngle + (newAngle - oldAngle) * _animation.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            if (blur)
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Opacity(
                    opacity: 0.7,
                    child: _CompassArrowPainterWidget(angle: angle, faded: faded),
                  ),
                ),
              )
            else
              _CompassArrowPainterWidget(angle: angle, faded: faded),
          ],
        );
      },
    );
  }
}

class _CompassArrowPainterWidget extends StatelessWidget {
  final double angle;
  final bool faded;
  const _CompassArrowPainterWidget({Key? key, required this.angle, required this.faded}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(48, 48),
      painter: EnhancedCompassPainter(angle: angle, faded: faded),
    );
  }
}

class EnhancedCompassPainter extends CustomPainter {
  final double angle;
  final bool faded;
  EnhancedCompassPainter({required this.angle, required this.faded});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final fadedColor = faded ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.33);
    final labelColor = faded ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.45);

    // Faint circle border
    final circlePaint = Paint()
      ..color = fadedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, circlePaint);

    // N/E/S/W faded labels
    final labels = ['N', 'E', 'S', 'W'];
    final labelAngles = [-pi/2, 0, pi/2, pi];
    for (int i = 0; i < labels.length; i++) {
      final labelOffset = Offset(
        center.dx + (radius + 8) * cos(labelAngles[i]),
        center.dy + (radius + 8) * sin(labelAngles[i]),
      );
      final textPainter = TextPainter(
        text: TextSpan(text: labels[i], style: TextStyle(color: labelColor, fontSize: 12, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, labelOffset - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Wind arrow
    final arrowPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final arrowLength = radius - 4;
    final arrowEnd = Offset(
      center.dx + arrowLength * -sin(angle),
      center.dy + arrowLength * -cos(angle),
    );
    canvas.drawLine(center, arrowEnd, arrowPaint);

    // Arrowhead
    final headSize = 10.0;
    final headAngle1 = angle + 0.3;
    final headAngle2 = angle - 0.3;
    final arrowHead1 = Offset(
      arrowEnd.dx + headSize * -sin(headAngle1),
      arrowEnd.dy + headSize * -cos(headAngle1),
    );
    final arrowHead2 = Offset(
      arrowEnd.dx + headSize * -sin(headAngle2),
      arrowEnd.dy + headSize * -cos(headAngle2),
    );
    canvas.drawLine(arrowEnd, arrowHead1, arrowPaint);
    canvas.drawLine(arrowEnd, arrowHead2, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant EnhancedCompassPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.faded != faded;
  }
}
