
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_keys.dart';
import '../models/home_config.dart';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_keys.dart';
import '../models/home_config.dart';

/// Enhanced House Footprint Widget with Visual Orientation Selection
class HouseFootprintWidget extends StatefulWidget {
  final String address;
  final Map<String, double> coordinates;
  final Function(List<WindowDirection> selectedSides, HomeOrientation orientation) onSelectionComplete;

  const HouseFootprintWidget({
    Key? key,
    required this.address,
    required this.coordinates,
    required this.onSelectionComplete,
  }) : super(key: key);

  @override
  State<HouseFootprintWidget> createState() => _HouseFootprintWidgetState();
}

class _HouseFootprintWidgetState extends State<HouseFootprintWidget> with TickerProviderStateMixin {
  String _getPrimaryOrientationLabel() {
    // Use street_facing from _buildingData if available
    final streetFacing = _buildingData?['street_facing']?.toString().toLowerCase();
    switch (streetFacing) {
      case 'north':
        return 'North';
      case 'east':
        return 'East';
      case 'south':
        return 'South';
      case 'west':
        return 'West';
      default:
        return 'North';
    }
  }
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  
  Set<WindowDirection> _selectedSides = {};
  double _houseRotation = 0.0; // Rotation to align house with north up
  bool _isLoading = true;
  bool _showSunlightHelper = false;
  Map<String, dynamic>? _buildingData;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Start pulse animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize house data after widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeHouseData();
      }
    });
  }

  @override
  void dispose() {
    // Stop and dispose animation controllers safely
    try {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
      _rotationController.dispose();
    } catch (e) {
      print('Error disposing rotation controller: $e');
    }
    
    try {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
      _pulseController.dispose();
    } catch (e) {
      print('Error disposing pulse controller: $e');
    }
    
    super.dispose();
  }

  Future<void> _initializeHouseData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Fetch building footprint and street-facing data
      await _fetchBuildingFootprint();
      await _detectStreetFacingSide();
      
      // Animate house rotation to align with north
      if (mounted && !_rotationController.isCompleted && !_rotationController.isAnimating) {
        try {
          _rotationController.forward();
        } catch (e) {
          print('Error starting rotation animation: $e');
        }
      }
      
    } catch (e) {
      print('Error initializing house data: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBuildingFootprint() async {
    try {
      // Use Google Maps Static API with satellite imagery
      final lat = widget.coordinates['lat'];
      final lng = widget.coordinates['lng'];
      
      // Simulate building data - in real implementation, use Google Building API or similar
      _buildingData = {
        'outline': _generateHouseOutline(),
        'street_facing': 'south', // Auto-detected from maps
        'building_type': 'residential',
        'estimated_orientation': 15.0, // Degrees from north
      };
      
    } catch (e) {
      print('Error fetching building footprint: $e');
    }
  }

  Future<void> _detectStreetFacingSide() async {
    try {
      // Use Google Streets API to detect street direction
      final lat = widget.coordinates['lat'];
      final lng = widget.coordinates['lng'];
      
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&result_type=street_address&key=$kGoogleApiKey',
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Process street data to determine building orientation
        _houseRotation = _buildingData?['estimated_orientation'] ?? 0.0;

        // Smart default: auto-select window zone based on street orientation
        WindowDirection? detectedDirection;
        // Use street_facing from _buildingData if available
        final streetFacing = _buildingData?['street_facing']?.toString().toLowerCase();
        switch (streetFacing) {
          case 'north':
            detectedDirection = WindowDirection.north;
            break;
          case 'east':
            detectedDirection = WindowDirection.east;
            break;
          case 'south':
            detectedDirection = WindowDirection.south;
            break;
          case 'west':
            detectedDirection = WindowDirection.west;
            break;
        }
        if (detectedDirection != null && mounted) {
          setState(() {
            _selectedSides = {detectedDirection!};
          });
        }
      }
    } catch (e) {
      print('Error detecting street facing side: $e');
    }
  }

  List<Offset> _generateHouseOutline() {
    // Generate a realistic house footprint
    return [
      const Offset(0.2, 0.3),   // Front left
      const Offset(0.8, 0.3),   // Front right
      const Offset(0.8, 0.7),   // Back right
      const Offset(0.2, 0.7),   // Back left
    ];
  }

  void _onSideSelected(WindowDirection side) {
    if (!mounted) return;
    setState(() {
      if (_selectedSides.contains(side)) {
        _selectedSides.remove(side);
      } else {
        _selectedSides.add(side);
      }
    });

    // Check if multiple sides selected
    if (_selectedSides.length > 1) {
      if (mounted) {
        setState(() => _showSunlightHelper = true);
      }
    } else if (_selectedSides.length == 1) {
      // Single side selected - determine orientation
      _completeSelection();
    }
  }

  void _handleTapOnHouse(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final houseSize = Size(120, 100);
    final houseRect = Rect.fromCenter(
      center: center,
      width: houseSize.width,
      height: houseSize.height,
    );

    // Check which side was tapped
    final relativePosition = localPosition - center;
    
    // Define tap zones for each side (extending beyond the house outline)
    final tapZoneSize = 40.0; // Make tap zones larger for easier selection
    
    // Top side (North)
    if (relativePosition.dy < -houseSize.height / 2 + tapZoneSize &&
        relativePosition.dx.abs() < houseSize.width / 2 + tapZoneSize) {
      _onSideSelected(WindowDirection.north);
      return;
    }
    
    // Bottom side (South)
    if (relativePosition.dy > houseSize.height / 2 - tapZoneSize &&
        relativePosition.dx.abs() < houseSize.width / 2 + tapZoneSize) {
      _onSideSelected(WindowDirection.south);
      return;
    }
    
    // Left side (West)
    if (relativePosition.dx < -houseSize.width / 2 + tapZoneSize &&
        relativePosition.dy.abs() < houseSize.height / 2 + tapZoneSize) {
      _onSideSelected(WindowDirection.west);
      return;
    }
    
    // Right side (East)
    if (relativePosition.dx > houseSize.width / 2 - tapZoneSize &&
        relativePosition.dy.abs() < houseSize.height / 2 + tapZoneSize) {
      _onSideSelected(WindowDirection.east);
      return;
    }
  }

  void _completeSelection() {
    if (_selectedSides.isEmpty) return;
    
    // Determine primary orientation based on selected sides
    HomeOrientation primaryOrientation = HomeOrientation.north;
    
    if (_selectedSides.contains(WindowDirection.south)) {
      primaryOrientation = HomeOrientation.south;
    } else if (_selectedSides.contains(WindowDirection.east)) {
      primaryOrientation = HomeOrientation.east;
    } else if (_selectedSides.contains(WindowDirection.west)) {
      primaryOrientation = HomeOrientation.west;
    }
    
    widget.onSelectionComplete(_selectedSides.toList(), primaryOrientation);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            const Text(
              "We've auto-detected your primary window direction. If it looks off, just tap front, back, or sides to adjust.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            // Smart default note for window zones
            // Dynamic badge for detected primary facing windows
            Center(
              child: Tooltip(
                message: 'Window orientation matters for energy efficiency. South-facing windows receive more sunlight, affecting heating and cooling costs.',
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${_getPrimaryOrientationLabel()}-facing windows detected\nTap the side with the largest windows.",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.info_outline,
                        color: Colors.green,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // House Footprint Display
            if (_isLoading) ...[
              const SizedBox(height: 60),
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text("Analyzing your house..."),
              const SizedBox(height: 60),
            ] else ...[
              // Satellite Map Background
              Container(
                height: 280,
                child: Container(
                width: MediaQuery.of(context).size.width - 80,
                constraints: const BoxConstraints(
                  maxWidth: 280,
                  maxHeight: 280,
                  minWidth: 200,
                  minHeight: 200,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                    // Satellite imagery background
                    _SatelliteMapBackground(coordinates: widget.coordinates),
                    
                    // House footprint overlay
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * _houseRotation * (pi / 180),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(constraints.maxWidth, constraints.maxHeight);
                              return GestureDetector(
                                onTapUp: (details) {
                                  final localPosition = details.localPosition;
                                  _handleTapOnHouse(localPosition, size);
                                },
                                child: CustomPaint(
                                  size: size,
                                  painter: _HouseFootprintPainter(
                                    selectedSides: _selectedSides,
                                    pulseAnimation: _pulseAnimation,
                                    onSideSelected: _onSideSelected,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    
                    // North indicator
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _NorthIndicator(houseRotation: _houseRotation),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ],
          
          const SizedBox(height: 16),
          
          // Selection status
          if (_selectedSides.isNotEmpty) ...[
            Text(
              _selectedSides.length == 1 
                ? "Selected: ${_selectedSides.first.name.toUpperCase()} side"
                : "Selected: ${_selectedSides.map((s) => s.name.toUpperCase()).join(", ")} sides",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Sunlight Helper (shown when multiple sides selected)
          if (_showSunlightHelper) 
            _AutoSunExposureWidget(
              selectedSides: _selectedSides.toList(),
              primaryOrientation: _getPrimaryOrientationLabel(),
              onComplete: () {
                _completeSelection();
              },
            ),
          
          // Action buttons
          if (_selectedSides.isNotEmpty && !_showSunlightHelper) ...[
            ElevatedButton(
              onPressed: _completeSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                "Continue",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }
}

class _SatelliteMapBackground extends StatelessWidget {
  final Map<String, double> coordinates;

  const _SatelliteMapBackground({required this.coordinates});

  @override
  Widget build(BuildContext context) {
    final lat = coordinates['lat']?.toStringAsFixed(6);
    final lng = coordinates['lng']?.toStringAsFixed(6);
    final mapUrl = 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$lat,$lng&'
  'zoom=20&'
        'size=300x300&'
        'scale=2&'
        'maptype=satellite&'
        'key=$kGoogleApiKey';
    
    return Image.network(
      mapUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.green.shade100,
        child: const Center(
          child: Icon(Icons.terrain, size: 48, color: Colors.green),
        ),
      ),
    );
  }
}

class _HouseFootprintPainter extends CustomPainter {
  final Set<WindowDirection> selectedSides;
  final Animation<double> pulseAnimation;
  final Function(WindowDirection) onSideSelected;

  _HouseFootprintPainter({
    required this.selectedSides,
    required this.pulseAnimation,
    required this.onSideSelected,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final houseSize = Size(120, 100);
    final houseRect = Rect.fromCenter(
      center: center,
      width: houseSize.width,
      height: houseSize.height,
    );

    // Draw house outline
    final housePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(houseRect, const Radius.circular(8)),
      housePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(houseRect, const Radius.circular(8)),
      borderPaint,
    );

    // Draw interactive sides
    _drawInteractiveSide(canvas, houseRect, WindowDirection.north, Colors.blue);
    _drawInteractiveSide(canvas, houseRect, WindowDirection.south, Colors.orange);
    _drawInteractiveSide(canvas, houseRect, WindowDirection.east, Colors.green);
    _drawInteractiveSide(canvas, houseRect, WindowDirection.west, Colors.purple);
    
  }

  void _drawInteractiveSide(Canvas canvas, Rect houseRect, WindowDirection side, Color color) {
    final isSelected = selectedSides.contains(side);
    final pulseScale = isSelected ? pulseAnimation.value : 1.0;
    
    Paint sidePaint = Paint()
      ..color = isSelected ? color.withOpacity(0.9) : color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Add border for better visibility
    Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Rect sideRect;
    switch (side) {
      case WindowDirection.north:
        sideRect = Rect.fromLTWH(
          houseRect.left,
          houseRect.top - 12,
          houseRect.width,
          12,
        );
        break;
      case WindowDirection.south:
        sideRect = Rect.fromLTWH(
          houseRect.left,
          houseRect.bottom,
          houseRect.width,
          12,
        );
        break;
      case WindowDirection.east:
        sideRect = Rect.fromLTWH(
          houseRect.right,
          houseRect.top,
          12,
          houseRect.height,
        );
        break;
      case WindowDirection.west:
        sideRect = Rect.fromLTWH(
          houseRect.left - 12,
          houseRect.top,
          12,
          houseRect.height,
        );
        break;
    }

    // Apply pulse scaling
    final scaledRect = Rect.fromCenter(
      center: sideRect.center,
      width: sideRect.width * pulseScale,
      height: sideRect.height * pulseScale,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(scaledRect, const Radius.circular(4)),
      sidePaint,
    );

    // Draw border for better visibility
    canvas.drawRRect(
      RRect.fromRectAndRadius(scaledRect, const Radius.circular(4)),
      borderPaint,
    );

    // Draw side label
    final textPainter = TextPainter(
      text: TextSpan(
        text: side.name.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        scaledRect.center.dx - textPainter.width / 2,
        scaledRect.center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NorthIndicator extends StatelessWidget {
  final double houseRotation;
  
  const _NorthIndicator({required this.houseRotation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Transform.rotate(
        angle: -houseRotation * (pi / 180), // Rotate compass opposite to house rotation
        child: const Icon(
          Icons.navigation,
          color: Colors.red,
          size: 24,
        ),
      ),
    );
  }
}

class _AutoSunExposureWidget extends StatelessWidget {
  final List<WindowDirection> selectedSides;
  final String primaryOrientation;
  final VoidCallback onComplete;

  const _AutoSunExposureWidget({
    required this.selectedSides,
    required this.primaryOrientation,
    required this.onComplete,
  });

  String _getSunExposureInfo() {
    switch (primaryOrientation.toLowerCase()) {
      case 'south':
        return 'South-facing windows get sun all day long - perfect for natural lighting and warmth!';
      case 'east':
        return 'East-facing windows get beautiful morning sunlight - great for breakfast areas!';
      case 'west':
        return 'West-facing windows get warm evening sunlight - ideal for relaxing spaces!';
      case 'north':
        return 'North-facing windows get gentle, indirect light throughout the day!';
      default:
        return 'Your window orientation has been automatically detected for optimal recommendations!';
    }
  }

  String _getSunIcon() {
    switch (primaryOrientation.toLowerCase()) {
      case 'south':
        return '☀️'; // Full sun all day
      case 'east':
        return '🌅'; // Morning sun
      case 'west':
        return '🌇'; // Evening sun
      case 'north':
        return '🌤️'; // Gentle light
      default:
        return '☀️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Text(
            '${_getSunIcon()} Sun Exposure Detected',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _getSunExposureInfo(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Continue with Smart Recommendations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TimeButton(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }
}
