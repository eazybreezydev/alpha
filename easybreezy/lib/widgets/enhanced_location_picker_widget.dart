import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_keys.dart';
import '../models/home_config.dart';
import 'house_footprint_widget.dart';

/// Enhanced Location Picker with Visual House Orientation Detection
class EnhancedLocationPickerWidget extends StatefulWidget {
  final String? initialAddress;
  final HomeOrientation? initialOrientation;
  final Map<String, double>? initialCoords;
  final String? selectedCountry; // Add country parameter
  final Function(String address, Map<String, double> coords, HomeOrientation orientation, List<WindowDirection> windows) onLocationSelected;
  final bool showTitle;

  const EnhancedLocationPickerWidget({
    Key? key,
    this.initialAddress,
    this.initialOrientation,
    this.initialCoords,
    this.selectedCountry, // Add country parameter to constructor
    required this.onLocationSelected,
    this.showTitle = true,
  }) : super(key: key);

  @override
  State<EnhancedLocationPickerWidget> createState() => _EnhancedLocationPickerWidgetState();
}

class _EnhancedLocationPickerWidgetState extends State<EnhancedLocationPickerWidget> {
  final TextEditingController _addressController = TextEditingController();
  
  List<String> _addressSuggestions = [];
  bool _isLoadingSuggestions = false;
  String _address = '';
  Map<String, double>? _selectedCoords;
  HomeOrientation _selectedOrientation = HomeOrientation.north;
  List<WindowDirection> _selectedWindows = [];

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
      // Build URL with country filtering if a country is selected
      String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&types=address&key=$kGoogleApiKey';
      
      // Add country restriction - use selected country or default to Canada
      String countryCode = widget.selectedCountry?.isNotEmpty == true ? widget.selectedCountry! : 'CA';
      url += '&components=country:$countryCode';
      print('DEBUG: Using country filter: $countryCode (selected: ${widget.selectedCountry})');
      
      
      final response = await http.get(Uri.parse(url));

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
    }

    setState(() {
      _isLoadingSuggestions = false;
    });
  }

  // Fetch coordinates for a given address
  Future<Map<String, double>?> _fetchPlaceCoordinates(String address) async {
    try {
      // Build URL with country filtering
      String url = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$kGoogleApiKey';
      
      // Add country restriction - use selected country or default to Canada
      String countryCode = widget.selectedCountry?.isNotEmpty == true ? widget.selectedCountry! : 'CA';
      url += '&components=country:$countryCode';
      print('DEBUG: Geocoding with country filter: $countryCode');
      
      
      final response = await http.get(Uri.parse(url));

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

  void _onHouseSelectionComplete(List<WindowDirection> selectedSides, HomeOrientation orientation) {
    setState(() {
      _selectedWindows = selectedSides;
      _selectedOrientation = orientation;
    });
    
    // Complete the location selection
    widget.onLocationSelected(_address, _selectedCoords!, _selectedOrientation, _selectedWindows);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          const Text(
            'Enhanced Location Setup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Combined Address and Window Selection
        Expanded(
          child: _HouseSelectionStep(
            address: _address,
            coordinates: _selectedCoords ?? {},
            addressController: _addressController,
            addressSuggestions: _addressSuggestions,
            isLoadingSuggestions: _isLoadingSuggestions,
            onAddressChanged: (value) {
              setState(() => _address = value);
              _fetchAddressSuggestions(value);
            },
            onAddressSubmitted: (value) async {
              if (value.isNotEmpty) {
                final coords = await _fetchPlaceCoordinates(value);
                if (coords != null) {
                  setState(() => _selectedCoords = coords);
                }
              }
            },
            onSuggestionTapped: (suggestion) async {
              setState(() {
                _address = suggestion;
                _addressController.text = suggestion;
                _addressSuggestions = [];
              });
              final coords = await _fetchPlaceCoordinates(suggestion);
              if (coords != null) {
                setState(() => _selectedCoords = coords);
              }
            },
            onSelectionComplete: _onHouseSelectionComplete,
          ),
        ),
      ],
    );
  }
}

class _HouseSelectionStep extends StatelessWidget {
  final TextEditingController addressController;
  final String address;
  final Map<String, double> coordinates;
  final List<String> addressSuggestions;
  final bool isLoadingSuggestions;
  final Function(String) onAddressChanged;
  final Function(String) onAddressSubmitted;
  final Function(String) onSuggestionTapped;
  final Function(List<WindowDirection>, HomeOrientation) onSelectionComplete;

  const _HouseSelectionStep({
    required this.addressController,
    required this.address,
    required this.coordinates,
    required this.addressSuggestions,
    required this.isLoadingSuggestions,
    required this.onAddressChanged,
    required this.onAddressSubmitted,
    required this.onSuggestionTapped,
    required this.onSelectionComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Address Input Field
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Home Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: addressController,
          decoration: const InputDecoration(
            hintText: '23 Main St',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: onAddressChanged,
          onSubmitted: onAddressSubmitted,
        ),
        // Address Suggestions
        if (addressSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 200), // Limit dropdown height
            child: SingleChildScrollView(
              child: Column(
                children: addressSuggestions.map((suggestion) => ListTile(
                  title: Text(suggestion),
                  onTap: () => onSuggestionTapped(suggestion),
                )).toList(),
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Satellite & Window Selection - Only show after valid address
        if (coordinates.isNotEmpty && address.isNotEmpty)
          Expanded(
            child: HouseFootprintWidget(
              address: address,
              coordinates: coordinates,
              onSelectionComplete: onSelectionComplete,
            ),
          )
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate appropriate sizes based on available height
                final availableHeight = constraints.maxHeight;
                final iconSize = availableHeight > 100 ? 48.0 : 32.0;
                final fontSize = availableHeight > 100 ? 14.0 : 12.0;
                final spacing = availableHeight > 100 ? 12.0 : 8.0;
                
                return Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.minHeight,
                        maxHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (availableHeight > 60) // Only show icon if enough space
                              Icon(
                                Icons.location_on,
                                size: iconSize,
                                color: Colors.grey.shade400,
                              ),
                            if (availableHeight > 60) SizedBox(height: spacing),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  availableHeight > 80 
                                    ? 'Enter your home address to see the satellite view'
                                    : 'Enter address above',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: availableHeight > 80 ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
