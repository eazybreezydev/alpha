import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../config/api_keys.dart';
import '../models/home_config.dart';

class LocationPickerWidget extends StatefulWidget {
  final String? initialAddress;
  final HomeOrientation? initialOrientation;
  final Map<String, double>? initialCoords;
  final Function(String address, Map<String, double> coords, HomeOrientation orientation) onLocationSelected;
  final bool showTitle;

  const LocationPickerWidget({
    Key? key,
    this.initialAddress,
    this.initialOrientation,
    this.initialCoords,
    required this.onLocationSelected,
    this.showTitle = true,
  }) : super(key: key);

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final TextEditingController _addressController = TextEditingController();
  List<String> _addressSuggestions = [];
  bool _isLoadingSuggestions = false;
  String _address = '';
  Map<String, double>? _selectedCoords;
  HomeOrientation _selectedOrientation = HomeOrientation.north;
  Map<WindowDirection, bool> _selectedWindows = {
    WindowDirection.north: false,
    WindowDirection.east: false,
    WindowDirection.south: false,
    WindowDirection.west: false,
  };

  @override
  void initState() {
    super.initState();
    // Initialize with provided values
    if (widget.initialAddress != null) {
      _address = widget.initialAddress!;
      _addressController.text = _address;
    }
    if (widget.initialOrientation != null) {
      _selectedOrientation = widget.initialOrientation!;
    }
    if (widget.initialCoords != null) {
      _selectedCoords = widget.initialCoords;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Fetch address suggestions from Google Places API
  Future<void> _fetchAddressSuggestions(String input) async {
    if (input.length < 3) {
      setState(() {
        _addressSuggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$kGoogleApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _addressSuggestions = (data['predictions'] as List)
                .map((prediction) => prediction['description'] as String)
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching address suggestions: $e');
    } finally {
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  // Fetch coordinates for an address
  Future<Map<String, double>?> _fetchPlaceCoordinates(String address) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$kGoogleApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return {
            'lat': location['lat'],
            'lng': location['lng'],
          };
        }
      }
    } catch (e) {
      print('Error fetching coordinates: $e');
    }
    return null;
  }

  void _notifyLocationSelected() {
    if (_address.isNotEmpty && _selectedCoords != null) {
      widget.onLocationSelected(_address, _selectedCoords!, _selectedOrientation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          const Text(
            'Location Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _addressController,
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Enter address',
            labelStyle: TextStyle(color: Colors.black87),
            hintText: '123 Main St, City, State',
            hintStyle: TextStyle(color: Colors.grey),
            suffixIcon: Icon(Icons.location_on),
          ),
          onChanged: (value) {
            setState(() {
              _address = value;
            });
            _fetchAddressSuggestions(value);
          },
          onFieldSubmitted: (value) async {
            if (value.isNotEmpty && _selectedCoords == null) {
              final coords = await _fetchPlaceCoordinates(value);
              if (coords != null) {
                setState(() {
                  _selectedCoords = coords;
                });
                _notifyLocationSelected();
              }
            }
          },
        ),
        if (_isLoadingSuggestions)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(),
          ),
        if (_addressSuggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 8.0),
            child: Card(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _addressSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _addressSuggestions[index];
                  return ListTile(
                    title: Text(
                      suggestion,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    onTap: () async {
                      setState(() {
                        _address = suggestion;
                        _addressController.text = suggestion;
                        _addressSuggestions = [];
                      });
                      final coords = await _fetchPlaceCoordinates(suggestion);
                      if (coords != null) {
                        setState(() {
                          _selectedCoords = coords;
                        });
                        _notifyLocationSelected();
                      }
                    },
                  );
                },
              ),
            ),
          ),
        // Show map if we have coordinates
        if (_selectedCoords != null && _address.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Static Map Preview with window selection overlay
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Satellite map
                    Builder(
                      builder: (context) {
                        final lat = _selectedCoords!['lat']?.toStringAsFixed(6);
                        final lng = _selectedCoords!['lng']?.toStringAsFixed(6);
                        final mapUrl =
                            'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=320x180&scale=2&markers=color:red%7C$lat,$lng&key=$kGoogleApiKey';
                        return Image.network(
                          mapUrl,
                          width: 320,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 320,
                            height: 180,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Text(
                                'Map preview unavailable',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // House outline overlay
                    Positioned(
                      left: 70,
                      top: 30,
                      child: SizedBox(
                        width: 180,
                        height: 120,
                        child: CustomPaint(
                          painter: _HouseOutlinePainter(),
                        ),
                      ),
                    ),
                    // Window zones (N/E/S/W)
                    ...WindowDirection.values.map((dir) {
                      final pos = _getZonePositionMap(dir);
                      final selected = _selectedWindows[dir] ?? false;
                      return Positioned(
                        left: pos.dx,
                        top: pos.dy,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedWindows[dir] = !selected;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: selected ? Colors.blueAccent : Colors.white,
                              border: Border.all(
                                color: selected ? Colors.blue : Colors.grey,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: selected
                                  ? [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 8)]
                                  : [],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.window,
                                color: selected ? Colors.white : Colors.blueGrey,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    // Direction labels
                    ...WindowDirection.values.map((dir) {
                      final pos = _getLabelPositionMap(dir);
                      return Positioned(
                        left: pos.dx,
                        top: pos.dy,
                        child: Text(
                          _getDirectionSymbol(dir),
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                    // Cross-breeze feedback
                    if (_isCrossBreezeEnabled())
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Cross-breeze enabled!',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
  // Map overlay positions for window zones
  Offset _getZonePositionMap(WindowDirection dir) {
    switch (dir) {
      case WindowDirection.north:
        return const Offset(150, 35);
      case WindowDirection.east:
        return const Offset(220, 80);
      case WindowDirection.south:
        return const Offset(150, 120);
      case WindowDirection.west:
        return const Offset(80, 80);
    }
  }

  Offset _getLabelPositionMap(WindowDirection dir) {
    switch (dir) {
      case WindowDirection.north:
        return const Offset(158, 20);
      case WindowDirection.east:
        return const Offset(240, 80);
      case WindowDirection.south:
        return const Offset(158, 140);
      case WindowDirection.west:
        return const Offset(60, 80);
    }
  }

  bool _isCrossBreezeEnabled() {
    final selected = _selectedWindows.entries.where((e) => e.value).map((e) => e.key).toSet();
    if (selected.contains(WindowDirection.north) && selected.contains(WindowDirection.south)) return true;
    if (selected.contains(WindowDirection.east) && selected.contains(WindowDirection.west)) return true;
    return false;
  }

// House outline painter for overlay
class _HouseOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    // Draw rectangle (house body)
    final rect = Rect.fromLTWH(40, 40, 100, 60);
    canvas.drawRect(rect, paint);
    // Draw triangle (roof)
    final roof = Path()
      ..moveTo(40, 40)
      ..lineTo(90, 10)
      ..lineTo(140, 40)
      ..close();
    canvas.drawPath(roof, paint..color = Colors.grey.shade400.withOpacity(0.7));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
          const SizedBox(height: 12),
          // Orientation Picker
          _OrientationPicker(
            selected: _selectedOrientation,
            onChanged: (orientation) {
              setState(() {
                _selectedOrientation = orientation;
              });
              _notifyLocationSelected();
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap a direction to set the building\'s front orientation',
            style: TextStyle(color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Current address info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _address.isNotEmpty ? _address : 'No address selected',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// Compass painter for the map overlay
class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 30.0;
    
    // Draw compass circle
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius, borderPaint);
    
    // Draw compass directions
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    final directions = ['N', 'E', 'S', 'W'];
    final angles = [0, 90, 180, 270];
    
    for (int i = 0; i < directions.length; i++) {
      final angle = angles[i] * (pi / 180);
      final x = center.dx + (radius - 15) * sin(angle);
      final y = center.dy - (radius - 15) * cos(angle);
      
      textPainter.text = TextSpan(
        text: directions[i],
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Orientation picker widget
class _OrientationPicker extends StatelessWidget {
  final HomeOrientation selected;
  final Function(HomeOrientation) onChanged;

  const _OrientationPicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          children: [
            // House outline overlay
            CustomPaint(
              size: const Size(180, 180),
              painter: _HouseOutlinePainter(),
            ),
            // Window zones (N/E/S/W)
            ...WindowDirection.values.map((dir) {
              final pos = _getZonePosition(dir);
              final selected = _selectedWindows[dir] ?? false;
              return Positioned(
                left: pos.dx,
                top: pos.dy,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedWindows[dir] = !selected;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected ? Colors.blueAccent : Colors.white,
                      border: Border.all(
                        color: selected ? Colors.blue : Colors.grey,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: selected
                          ? [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 8)]
                          : [],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.window,
                        color: selected ? Colors.white : Colors.blueGrey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              );
            }),
            // Direction labels
            ...WindowDirection.values.map((dir) {
              final pos = _getLabelPosition(dir);
              return Positioned(
                left: pos.dx,
                top: pos.dy,
                child: Text(
                  _getDirectionSymbol(dir),
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );
            }),
            // Cross-breeze feedback
            if (_isCrossBreezeEnabled())
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Cross-breeze enabled!',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  Offset _getZonePosition(WindowDirection dir) {
    switch (dir) {
      case WindowDirection.north:
        return const Offset(72, 10);
      case WindowDirection.east:
        return const Offset(140, 72);
      case WindowDirection.south:
        return const Offset(72, 140);
      case WindowDirection.west:
        return const Offset(10, 72);
    }
  }

  Offset _getLabelPosition(WindowDirection dir) {
    switch (dir) {
      case WindowDirection.north:
        return const Offset(80, 0);
      case WindowDirection.east:
        return const Offset(160, 80);
      case WindowDirection.south:
        return const Offset(80, 160);
      case WindowDirection.west:
        return const Offset(0, 80);
    }
  }

  bool _isCrossBreezeEnabled() {
    final selected = _selectedWindows.entries.where((e) => e.value).map((e) => e.key).toSet();
    if (selected.contains(WindowDirection.north) && selected.contains(WindowDirection.south)) return true;
    if (selected.contains(WindowDirection.east) && selected.contains(WindowDirection.west)) return true;
    return false;
  }
// House outline painter for overlay
class _HouseOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    // Draw rectangle (house body)
    final rect = Rect.fromLTWH(40, 60, 100, 60);
    canvas.drawRect(rect, paint);
    // Draw triangle (roof)
    final roof = Path()
      ..moveTo(40, 60)
      ..lineTo(90, 30)
      ..lineTo(140, 60)
      ..close();
    canvas.drawPath(roof, paint..color = Colors.grey.shade400.withOpacity(0.7));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
  }

  double _getAngleForOrientation(HomeOrientation orientation) {
    switch (orientation) {
      case HomeOrientation.north:
        return 0;
      case HomeOrientation.east:
        return pi / 2;
      case HomeOrientation.south:
        return pi;
      case HomeOrientation.west:
        return 3 * pi / 2;
    }
  }

  String _getOrientationSymbol(HomeOrientation orientation) {
    switch (orientation) {
      case HomeOrientation.north:
        return 'N';
      case HomeOrientation.east:
        return 'E';
      case HomeOrientation.south:
        return 'S';
      case HomeOrientation.west:
        return 'W';
    }
  }
}
