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
          // Static Map Preview
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
                    // Compass overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _CompassPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
      child: Container(
        width: 120,
        height: 120,
        child: Stack(
          children: [
            // Center house icon
            Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: const Icon(
                  Icons.home,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
            ),
            // Direction buttons
            ...HomeOrientation.values.map((orientation) {
              final angle = _getAngleForOrientation(orientation);
              final isSelected = selected == orientation;
              
              return Positioned(
                left: 60 + 35 * cos(angle - pi / 2) - 15,
                top: 60 + 35 * sin(angle - pi / 2) - 15,
                child: GestureDetector(
                  onTap: () => onChanged(orientation),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getOrientationSymbol(orientation),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
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
