import 'dart:math';
import 'package:flutter/material.dart';

class WindFlowOverlay extends StatefulWidget {
  final double windSpeed;
  final String windDirection;
  final bool subtleMode;

  const WindFlowOverlay({
    super.key,
    required this.windSpeed,
    required this.windDirection,
    this.subtleMode = false,
  });

  @override
  State<WindFlowOverlay> createState() => _WindFlowOverlayState();
}

class _WindFlowOverlayState extends State<WindFlowOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late WindStreakManager _streakManager;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _streakManager = WindStreakManager();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WindFlowOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.windSpeed != widget.windSpeed ||
        oldWidget.windDirection != widget.windDirection ||
        oldWidget.subtleMode != widget.subtleMode) {
      _streakManager.updateWindParameters(
        widget.windSpeed,
        widget.windDirection,
        widget.subtleMode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WindFlowPainter(
            _streakManager,
            _controller.value,
            windSpeed: widget.windSpeed,
            windDirection: widget.windDirection,
            subtleMode: widget.subtleMode,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class WindStreak {
  List<Offset> points;
  double opacity;
  double thickness;
  double speed;
  double lifetime;
  double age;
  Color color;
  int layer;

  WindStreak({
    required this.points,
    required this.opacity,
    required this.thickness,
    required this.speed,
    required this.lifetime,
    this.age = 0.0,
    required this.color,
    this.layer = 0,
  });

  bool get isAlive => age < lifetime;

  void update(double deltaTime, Size canvasSize, WindStreakManager manager) {
    // Validate inputs
    if (!_isValidDouble(deltaTime) || deltaTime <= 0 || deltaTime > 1.0) {
      deltaTime = 0.016; // Default to 60fps
    }
    
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return;
    
    age += deltaTime;
    
    // Update opacity based on age for fading effect
    if (lifetime > 0) {
      double ageRatio = age / lifetime;
      opacity = ((1.0 - ageRatio) * 1.0).clamp(0.0, 1.0); // Maximum opacity to 1.0 for high visibility
    }
    
    // Move head point based on flow field
    if (points.isNotEmpty) {
      Offset currentPoint = points[0];
      
      // Validate current point
      if (!_isValidPoint(currentPoint)) {
        _resetStreak(canvasSize);
        return;
      }
      
      Offset flowVector = manager.getFlowVector(currentPoint, canvasSize);
      
      // Validate flow vector
      if (!_isValidPoint(flowVector)) {
        flowVector = const Offset(1.0, 0.0); // Default flow
      }
      
      // Apply movement with organic variation to head only
      double randomOffset = (Random().nextDouble() - 0.5) * 0.2;
      Offset movement = Offset(
        (flowVector.dx * speed + randomOffset).clamp(-50.0, 50.0),
        (flowVector.dy * speed * 0.3).clamp(-20.0, 20.0), // Reduce vertical movement
      );
      
      Offset newHeadPosition = currentPoint + movement;
      
      // Validate new head position
      if (!_isValidPoint(newHeadPosition)) {
        _resetStreak(canvasSize);
        return;
      }
      
      // Update trail using proper queue-based system to prevent folding
      _updateTrailPoints(newHeadPosition);
    }
    
    // Wrap around screen edges for head point only
    if (points.isNotEmpty) {
      if (points[0].dx > canvasSize.width + 50) {
        // Reset entire streak when head goes off screen
        _resetStreak(canvasSize);
      }
      if (points[0].dy < -50 || points[0].dy > canvasSize.height + 50) {
        _resetStreak(canvasSize);
      }
    }
  }

  void _updateTrailPoints(Offset newHeadPosition) {
    // Validate new head position
    if (!_isValidPoint(newHeadPosition)) return;
    
    // Queue-based trail system - each point follows at a fixed distance
    const double segmentDistance = 12.0; // Fixed distance between segments
    
    List<Offset> newPoints = [newHeadPosition];
    
    // Calculate trail points by walking backwards from head at fixed distances
    for (int i = 1; i < points.length; i++) {
      Offset previousPos = newPoints[i - 1];
      Offset oldPos = points[i];
      
      // Validate positions
      if (!_isValidPoint(previousPos) || !_isValidPoint(oldPos)) {
        // Use a safe default position
        newPoints.add(Offset(newHeadPosition.dx - (i * segmentDistance), newHeadPosition.dy));
        continue;
      }
      
      // Direction from current trail point to previous point
      Offset direction = previousPos - oldPos;
      double distance = direction.distance;
      
      // Validate distance
      if (!_isValidDouble(distance) || distance <= 0) {
        newPoints.add(oldPos);
        continue;
      }
      
      Offset newPos;
      if (distance <= segmentDistance * 0.5) {
        // If too close, keep current position
        newPos = oldPos;
      } else if (distance >= segmentDistance * 2.0) {
        // If too far, jump closer
        Offset normalizedDir = direction / distance;
        if (!_isValidPoint(normalizedDir)) {
          normalizedDir = const Offset(1.0, 0.0);
        }
        newPos = previousPos - (normalizedDir * segmentDistance);
      } else {
        // Normal following at fixed distance
        Offset normalizedDir = direction / distance;
        if (!_isValidPoint(normalizedDir)) {
          normalizedDir = const Offset(1.0, 0.0);
        }
        newPos = previousPos - (normalizedDir * segmentDistance);
      }
      
      // Validate final position
      if (!_isValidPoint(newPos)) {
        newPos = Offset(newHeadPosition.dx - (i * segmentDistance), newHeadPosition.dy);
      }
      
      newPoints.add(newPos);
    }
    
    points = newPoints;
  }
  void _resetStreak(Size canvasSize) {
    // Reset all points to a new spawn position
    final spawnX = -50.0;
    final spawnY = Random().nextDouble() * canvasSize.height;
    final spawnPos = Offset(spawnX, spawnY);
    
    for (int i = 0; i < points.length; i++) {
      points[i] = spawnPos;
    }
    age = 0.0;
  }

  // Helper method to validate if a point is safe for drawing
  bool _isValidPoint(Offset point) {
    return _isValidDouble(point.dx) && _isValidDouble(point.dy);
  }

  // Helper method to validate if a double is safe for painting
  bool _isValidDouble(double value) {
    return !value.isNaN && !value.isInfinite && value.abs() < 1000000;
  }
}

class WindStreakManager {
  List<WindStreak> streaks = [];
  Random random = Random();
  double lastSpawnTime = 0;
  double spawnInterval = 0.05; // Spawn every 50ms for dense effect

  void updateWindParameters(double windSpeed, String windDirection, bool subtleMode) {
    // Realistically scaled streak counts based on actual wind conditions
    int baseStreakCount;
    
    if (windSpeed < 1) {
      // Calm: very minimal streaks
      baseStreakCount = subtleMode ? 2 : 5;
    } else if (windSpeed < 5) {
      // Light air: subtle animation
      baseStreakCount = subtleMode ? 5 : 10;
    } else if (windSpeed < 11) {
      // Light breeze: noticeable but gentle
      baseStreakCount = subtleMode ? 10 : 18;
    } else if (windSpeed < 19) {
      // Gentle breeze: moderate animation (15 km/h falls here)
      baseStreakCount = subtleMode ? 18 : 30;
    } else if (windSpeed < 28) {
      // Moderate breeze: more active
      baseStreakCount = subtleMode ? 30 : 50;
    } else if (windSpeed < 38) {
      // Fresh breeze: quite active
      baseStreakCount = subtleMode ? 50 : 75;
    } else {
      // Strong winds: very active animation
      baseStreakCount = subtleMode ? 75 : 120;
    }
    
    // Add minimal variation based on exact wind speed
    int windVariation = (windSpeed * 0.5).round();
    int targetStreakCount = baseStreakCount + windVariation;
    
    // Reasonable limits for realistic animation
    targetStreakCount = targetStreakCount.clamp(2, 150);
    
    // Spawn rates that match wind intensity
    if (windSpeed < 1) {
      spawnInterval = subtleMode ? 0.5 : 0.3; // Very slow for calm
    } else if (windSpeed < 5) {
      spawnInterval = subtleMode ? 0.3 : 0.2; // Slow for light air
    } else if (windSpeed < 11) {
      spawnInterval = subtleMode ? 0.2 : 0.15; // Moderate for light breeze
    } else if (windSpeed < 19) {
      spawnInterval = subtleMode ? 0.15 : 0.1; // Gentle breeze rate
    } else if (windSpeed < 28) {
      spawnInterval = subtleMode ? 0.1 : 0.08; // Moderate breeze
    } else if (windSpeed < 38) {
      spawnInterval = subtleMode ? 0.08 : 0.05; // Fresh breeze
    } else {
      spawnInterval = subtleMode ? 0.05 : 0.03; // Fast for strong winds
    }
  }

  void update(double deltaTime, Size canvasSize, double windSpeed, String windDirection, bool subtleMode) {
    lastSpawnTime += deltaTime;
    
    // Realistic active streak limits based on wind conditions
    int maxStreaks;
    if (windSpeed < 1) {
      maxStreaks = subtleMode ? 2 : 4; // Very minimal for calm
    } else if (windSpeed < 5) {
      maxStreaks = subtleMode ? 4 : 8; // Subtle for light air
    } else if (windSpeed < 11) {
      maxStreaks = subtleMode ? 8 : 15; // Light breeze
    } else if (windSpeed < 19) {
      maxStreaks = subtleMode ? 15 : 25; // Gentle breeze (realistic for 15km/h)
    } else if (windSpeed < 28) {
      maxStreaks = subtleMode ? 25 : 40; // Moderate breeze
    } else if (windSpeed < 38) {
      maxStreaks = subtleMode ? 40 : 60; // Fresh breeze
    } else {
      maxStreaks = subtleMode ? 60 : 100; // Strong winds
    }
    
    // Spawn new streaks only if we haven't reached the limit
    if (lastSpawnTime >= spawnInterval && streaks.length < maxStreaks) {
      _spawnStreak(canvasSize, windSpeed, subtleMode);
      lastSpawnTime = 0;
    }
    
    // Update existing streaks
    for (int i = streaks.length - 1; i >= 0; i--) {
      streaks[i].update(deltaTime, canvasSize, this);
      if (!streaks[i].isAlive) {
        streaks.removeAt(i);
      }
    }
  }

  void _spawnStreak(Size canvasSize, double windSpeed, bool subtleMode) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return;
    
    // Realistic spawn probability based on wind conditions
    if (windSpeed < 1 && random.nextDouble() < 0.7) {
      return; // Skip 70% of spawn attempts for calm conditions
    } else if (windSpeed < 5 && random.nextDouble() < 0.5) {
      return; // Skip 50% for light air
    } else if (windSpeed < 11 && random.nextDouble() < 0.3) {
      return; // Skip 30% for light breeze
    } else if (windSpeed < 19 && random.nextDouble() < 0.2) {
      return; // Skip 20% for gentle breeze
    } else if (windSpeed < 28 && random.nextDouble() < 0.1) {
      return; // Skip 10% for moderate breeze
    }
    // No skipping for stronger winds
    
    // Create initial points for the streak with proper spacing
    int pointCount;
    if (windSpeed < 1) {
      pointCount = 3 + random.nextInt(2); // Very short for calm
    } else if (windSpeed < 5) {
      pointCount = 4 + random.nextInt(3); // Short streaks for light air
    } else if (windSpeed < 11) {
      pointCount = 5 + random.nextInt(3); // Light breeze
    } else if (windSpeed < 19) {
      pointCount = 6 + random.nextInt(4); // Gentle breeze (moderate length)
    } else if (windSpeed < 28) {
      pointCount = 8 + random.nextInt(4); // Moderate breeze
    } else if (windSpeed < 38) {
      pointCount = 10 + random.nextInt(6); // Fresh breeze
    } else {
      pointCount = 12 + random.nextInt(8); // Longer streaks for strong wind
    }
    
    List<Offset> points = [];
    
    // Start from left edge with random vertical position
    double startY = random.nextDouble() * canvasSize.height;
    double startX = -100 - random.nextDouble() * 50; // Start off-screen
    
    // Create properly spaced trail points going backwards from head
    const double initialSpacing = 12.0;
    
    for (int i = 0; i < pointCount; i++) {
      // Each point is positioned at a fixed distance behind the previous
      double x = startX - (i * initialSpacing);
      double y = startY + sin(i * 0.3) * (3 + random.nextDouble() * 4); // Gentle wave
      points.add(Offset(x, y));
    }
    
    // Determine layer for depth effect (0 = background, 2 = foreground)
    int layer = random.nextInt(3);
    
    // Realistic opacity and thickness based on wind speed
    double baseOpacity, baseThickness;
    if (windSpeed < 1) {
      // Calm: barely visible
      baseOpacity = subtleMode ? 0.1 : 0.2;
      baseThickness = subtleMode ? 0.5 : 0.8;
    } else if (windSpeed < 5) {
      // Light air: very subtle
      baseOpacity = subtleMode ? 0.2 : 0.35;
      baseThickness = subtleMode ? 0.6 : 1.0;
    } else if (windSpeed < 11) {
      // Light breeze: noticeable but gentle
      baseOpacity = subtleMode ? 0.3 : 0.5;
      baseThickness = subtleMode ? 0.8 : 1.2;
    } else if (windSpeed < 19) {
      // Gentle breeze: moderate visibility (15 km/h should look gentle)
      baseOpacity = subtleMode ? 0.4 : 0.6;
      baseThickness = subtleMode ? 1.0 : 1.4;
    } else if (windSpeed < 28) {
      // Moderate breeze: clearly visible
      baseOpacity = subtleMode ? 0.5 : 0.7;
      baseThickness = subtleMode ? 1.2 : 1.6;
    } else if (windSpeed < 38) {
      // Fresh breeze: prominent
      baseOpacity = subtleMode ? 0.6 : 0.8;
      baseThickness = subtleMode ? 1.4 : 1.8;
    } else {
      // Strong winds: highly visible
      baseOpacity = subtleMode ? 0.7 : 0.9;
      baseThickness = subtleMode ? 1.6 : 2.0;
    }
    
    // Create streak with wind-speed-adjusted properties
    WindStreak streak = WindStreak(
      points: points,
      opacity: baseOpacity + random.nextDouble() * (baseOpacity * 0.8),
      thickness: baseThickness + random.nextDouble() * baseThickness,
      speed: (windSpeed * 0.3 + random.nextDouble() * 0.4) * (layer + 1), // Faster in foreground
      lifetime: 4.0 + random.nextDouble() * 3.0,
      color: _getLayerColor(layer, windSpeed),
      layer: layer,
    );
    
    streaks.add(streak);
  }

  Color _getLayerColor(int layer, double windSpeed) {
    // Adjust color intensity based on wind speed (realistic scaling)
    double intensityMultiplier;
    if (windSpeed < 1) {
      intensityMultiplier = 0.8; // Very subtle for calm
    } else if (windSpeed < 5) {
      intensityMultiplier = 1.0; // Subtle for light air
    } else if (windSpeed < 11) {
      intensityMultiplier = 1.2; // Light breeze
    } else if (windSpeed < 19) {
      intensityMultiplier = 1.4; // Gentle breeze (realistic for 15 km/h)
    } else if (windSpeed < 28) {
      intensityMultiplier = 1.6; // Moderate breeze
    } else if (windSpeed < 38) {
      intensityMultiplier = 1.8; // Fresh breeze
    } else {
      intensityMultiplier = 2.0; // Strong winds
    }
    
    // Different colors for depth layering with realistic contrast
    switch (layer) {
      case 0: // Background layer - subtle blue
        return Colors.blue.shade700.withOpacity((0.4 * intensityMultiplier).clamp(0.0, 1.0));
      case 1: // Middle layer - light gray for contrast
        return Colors.grey.shade300.withOpacity((0.5 * intensityMultiplier).clamp(0.0, 1.0));
      case 2: // Foreground layer - white but not overwhelming
        return Colors.white.withOpacity((0.6 * intensityMultiplier).clamp(0.0, 1.0));
      default:
        return Colors.grey.shade400.withOpacity((0.5 * intensityMultiplier).clamp(0.0, 1.0));
    }
  }

  Offset getFlowVector(Offset position, Size canvasSize) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) {
      return const Offset(1.0, 0.0);
    }
    
    // Validate position
    if (position.dx.isNaN || position.dx.isInfinite || 
        position.dy.isNaN || position.dy.isInfinite) {
      return const Offset(1.0, 0.0);
    }
    
    // Normalize position for flow field calculation
    double x = (position.dx / canvasSize.width).clamp(-10.0, 10.0);
    double y = (position.dy / canvasSize.height).clamp(-10.0, 10.0);
    
    // Create flowing horizontal field with subtle curves
    double flowX = 1.0 + 0.3 * sin(y * pi * 2 + x * pi); // Gentle waves
    double flowY = 0.2 * sin(x * pi * 3) * cos(y * pi * 2); // Subtle vertical variation
    
    // Add some noise for organic movement
    double noise = _noise(x * 5, y * 5) * 0.1;
    flowX += noise;
    flowY += noise * 0.5;
    
    // Validate and clamp the result
    if (flowX.isNaN || flowX.isInfinite) flowX = 1.0;
    if (flowY.isNaN || flowY.isInfinite) flowY = 0.0;
    
    flowX = flowX.clamp(-5.0, 5.0);
    flowY = flowY.clamp(-2.0, 2.0);
    
    Offset result = Offset(flowX, flowY);
    
    // Normalize safely
    double magnitude = result.distance;
    if (magnitude.isNaN || magnitude.isInfinite || magnitude == 0) {
      return const Offset(1.0, 0.0);
    }
    
    return result / magnitude;
  }

  // Simple noise function for organic movement
  double _noise(double x, double y) {
    if (x.isNaN || x.isInfinite || y.isNaN || y.isInfinite) {
      return 0.0;
    }
    
    // Clamp inputs to reasonable values
    x = x.clamp(-1000.0, 1000.0);
    y = y.clamp(-1000.0, 1000.0);
    
    double result = sin(x * 12.9898 + y * 78.233) * 43758.5453;
    result = result - result.floor(); // Get fractional part
    
    if (result.isNaN || result.isInfinite) {
      return 0.0;
    }
    
    return result.clamp(0.0, 1.0) * 2.0 - 1.0; // Convert to -1 to 1 range
  }
}

class WindFlowPainter extends CustomPainter {
  final WindStreakManager streakManager;
  final double animationValue;
  final double windSpeed;
  final String windDirection;
  final bool subtleMode;

  WindFlowPainter(
    this.streakManager,
    this.animationValue, {
    required this.windSpeed,
    required this.windDirection,
    required this.subtleMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    
    // Update streak manager
    streakManager.update(0.016, size, windSpeed, windDirection, subtleMode); // ~60fps
    
    // Sort streaks by layer for proper depth rendering
    List<WindStreak> sortedStreaks = List.from(streakManager.streaks);
    sortedStreaks.sort((a, b) => a.layer.compareTo(b.layer));
    
    // Draw streaks
    for (WindStreak streak in sortedStreaks) {
      _drawStreak(canvas, streak);
    }
  }

  void _drawStreak(Canvas canvas, WindStreak streak) {
    if (streak.points.length < 2) return;
    
    // Validate all points before drawing
    bool hasValidPoints = true;
    for (Offset point in streak.points) {
      if (!_isValidPoint(point)) {
        hasValidPoints = false;
        break;
      }
    }
    
    if (!hasValidPoints) return;
    
    // Validate streak properties
    if (!_isValidDouble(streak.opacity) || 
        !_isValidDouble(streak.thickness) ||
        streak.opacity <= 0 || 
        streak.thickness <= 0) {
      return;
    }
    
    // Create path with tapered effect
    Path path = Path();
    path.moveTo(streak.points.first.dx, streak.points.first.dy);
    
    for (int i = 1; i < streak.points.length; i++) {
      path.lineTo(streak.points[i].dx, streak.points[i].dy);
      
      // Draw tapered segments with decreasing opacity
      if (i > 1) {
        double segmentProgress = i / (streak.points.length - 1);
        double taperOpacity = streak.opacity * (1.0 - segmentProgress * 0.7);
        double taperWidth = streak.thickness * (1.0 - segmentProgress * 0.5);
        
        // Validate calculated values
        if (!_isValidDouble(taperOpacity) || 
            !_isValidDouble(taperWidth) ||
            taperOpacity <= 0 || 
            taperWidth <= 0) {
          continue;
        }
        
        // Clamp values to safe ranges
        taperOpacity = taperOpacity.clamp(0.0, 1.0);
        taperWidth = taperWidth.clamp(0.1, 10.0);
        
        Paint segmentPaint = Paint()
          ..color = streak.color.withOpacity(taperOpacity)
          ..strokeWidth = taperWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        
        Path segmentPath = Path();
        segmentPath.moveTo(streak.points[i - 1].dx, streak.points[i - 1].dy);
        segmentPath.lineTo(streak.points[i].dx, streak.points[i].dy);
        
        try {
          canvas.drawPath(segmentPath, segmentPaint);
        } catch (e) {
          // Skip this segment if drawing fails
          continue;
        }
      }
    }
  }

  // Helper method to validate if a point is safe for drawing
  bool _isValidPoint(Offset point) {
    return _isValidDouble(point.dx) && _isValidDouble(point.dy);
  }

  // Helper method to validate if a double is safe for painting
  bool _isValidDouble(double value) {
    return !value.isNaN && !value.isInfinite && value.abs() < 1000000;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension OffsetExtensions on Offset {
  Offset normalized() {
    double magnitude = distance;
    if (magnitude == 0) return const Offset(0, 0);
    return this / magnitude;
  }
}
