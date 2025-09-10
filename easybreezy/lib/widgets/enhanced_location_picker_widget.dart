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
  final PageController _pageController = PageController();
  
  List<String> _addressSuggestions = [];
  bool _isLoadingSuggestions = false;
  String _address = '';
  Map<String, double>? _selectedCoords;
  HomeOrientation _selectedOrientation = HomeOrientation.north;
  List<WindowDirection> _selectedWindows = [];
  int _currentStep = 0;

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
    _pageController.dispose();
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

  void _proceedToHouseSelection() {
    if (_address.isNotEmpty && _selectedCoords != null) {
      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onHouseSelectionComplete(List<WindowDirection> selectedSides, HomeOrientation orientation) {
    setState(() {
      _selectedWindows = selectedSides;
      _selectedOrientation = orientation;
    });
    
    // Complete the location selection
    widget.onLocationSelected(_address, _selectedCoords!, _selectedOrientation, _selectedWindows);
  }

  void _goBackToAddressStep() {
    setState(() => _currentStep = 0);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
        
  // ...existing code...
        
        // Page view for steps
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Step 1: Address Input
              _AddressInputStep(
                addressController: _addressController,
                address: _address,
                selectedCoords: _selectedCoords,
                addressSuggestions: _addressSuggestions,
                isLoadingSuggestions: _isLoadingSuggestions,
                onAddressChanged: (value) {
                  setState(() => _address = value);
                  _fetchAddressSuggestions(value);
                },
                onAddressSubmitted: (value) async {
                  if (value.isNotEmpty && _selectedCoords == null) {
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
                onContinue: _proceedToHouseSelection,
              ),
              
              // Step 2: House Footprint Selection
              if (_selectedCoords != null)
                _HouseSelectionStep(
                  address: _address,
                  coordinates: _selectedCoords!,
                  onSelectionComplete: _onHouseSelectionComplete,
                  onBack: _goBackToAddressStep,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final int currentStep;

  const _ProgressIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepIndicator(
          stepNumber: 1,
          title: 'Enter Address',
          isActive: currentStep == 0,
          isCompleted: currentStep > 0,
        ),
        Expanded(
          child: Container(
            height: 2,
            color: currentStep > 0 ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        _StepIndicator(
          stepNumber: 2,
          title: 'Select Windows',
          isActive: currentStep == 1,
          isCompleted: false,
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int stepNumber;
  final String title;
  final bool isActive;
  final bool isCompleted;

  const _StepIndicator({
    required this.stepNumber,
    required this.title,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted 
                ? Colors.green 
                : isActive 
                    ? Colors.blue 
                    : Colors.grey.shade300,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    stepNumber.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _AddressInputStep extends StatelessWidget {
  final TextEditingController addressController;
  final String address;
  final Map<String, double>? selectedCoords;
  final List<String> addressSuggestions;
  final bool isLoadingSuggestions;
  final Function(String) onAddressChanged;
  final Function(String) onAddressSubmitted;
  final Function(String) onSuggestionTapped;
  final VoidCallback onContinue;

  const _AddressInputStep({
    required this.addressController,
    required this.address,
    required this.selectedCoords,
    required this.addressSuggestions,
    required this.isLoadingSuggestions,
    required this.onAddressChanged,
    required this.onAddressSubmitted,
    required this.onSuggestionTapped,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter your home address so we can locate your house on the map.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
        
        TextFormField(
          controller: addressController,
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Home Address',
            labelStyle: TextStyle(color: Colors.black87),
            hintText: '123 Main St, City, State',
            hintStyle: TextStyle(color: Colors.grey),
            suffixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
          onChanged: onAddressChanged,
          onFieldSubmitted: onAddressSubmitted,
        ),
        
        if (isLoadingSuggestions)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(),
          ),
          
        if (addressSuggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 8.0),
            child: Card(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: addressSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = addressSuggestions[index];
                  return ListTile(
                    title: Text(
                      suggestion,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    onTap: () => onSuggestionTapped(suggestion),
                  );
                },
              ),
            ),
          ),
          
        // Show map preview when coordinates are available
        if (selectedCoords != null && address.isNotEmpty) ...[
          const SizedBox(height: 24),
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
                child: Image.network(
                  'https://maps.googleapis.com/maps/api/staticmap?center=${selectedCoords!['lat']?.toStringAsFixed(6)},${selectedCoords!['lng']?.toStringAsFixed(6)}&zoom=16&size=300x200&scale=2&markers=color:red%7C${selectedCoords!['lat']?.toStringAsFixed(6)},${selectedCoords!['lng']?.toStringAsFixed(6)}&key=$kGoogleApiKey',
                  width: 300,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 300,
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text(
                        'Map preview unavailable',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        ],
      ),
    );
  }
}

class _HouseSelectionStep extends StatelessWidget {
  final String address;
  final Map<String, double> coordinates;
  final Function(List<WindowDirection>, HomeOrientation) onSelectionComplete;
  final VoidCallback onBack;

  const _HouseSelectionStep({
    required this.address,
    required this.coordinates,
    required this.onSelectionComplete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Select Window Locations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: HouseFootprintWidget(
            address: address,
            coordinates: coordinates,
            onSelectionComplete: onSelectionComplete,
          ),
        ),
      ],
    );
  }
}
