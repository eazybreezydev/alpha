import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/home_config.dart';
import '../providers/home_provider.dart';
import 'main_shell.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;
  
  // Home configuration stored during onboarding
  HomeOrientation? _selectedOrientation;
  final Map<WindowDirection, bool> _selectedWindows = {
    WindowDirection.north: false,
    WindowDirection.east: false,
    WindowDirection.south: false,
    WindowDirection.west: false,
  };
  
  // Address-related state variables
  late String _address;
  late TextEditingController _addressController;
  String? _selectedCountry;
  static const String kGoogleApiKey = 'AIzaSyBmZfcpnFKGRr2uzcL3ayXxUN-_fX6fy7s';
  List<String> _addressSuggestions = [];
  bool _isLoadingSuggestions = false;
  Map<String, double>? _selectedCoords;

  @override
  void initState() {
    super.initState();
    _address = '';
    _addressController = TextEditingController(text: _address);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Validation for the Home Orientation page (page index 1)
    if (_currentPage == 1) {
      bool canProceed = true;
      String errorMessage = '';
      
      // Check if country is selected
      if (_selectedCountry == null) {
        canProceed = false;
        errorMessage = 'Please select your country';
      }
      // Check if address is filled
      else if (_address.trim().isEmpty) {
        canProceed = false;
        errorMessage = 'Please enter your home address';
      }
      // Check if orientation is selected (this check will happen even if address is empty)
      else if (_selectedOrientation == null) {
        canProceed = false;
        errorMessage = 'Please select which direction your home faces';
      }
      
      if (!canProceed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return; // Don't proceed to next page
      }
    }
    
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // On the last page (notifications), complete onboarding
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgrounds/dayv2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
          children: [
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildHomeOrientationPage(),
                  _buildWindowConfigPage(),
                ],
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Required fields note (only show on page 1 - home orientation)
                  if (_currentPage == 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, 
                               size: 16, 
                               color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Fields marked with * are required',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Back'),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        textStyle: const TextStyle(fontSize: 24),
                      ),
                      child: Text(_currentPage < _totalPages - 1 ? 'Next' : 'Get Started'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDotProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20), // Add some top spacing
          const Text(
            'Welcome to EasyBreezy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24), // Reduced from 32
          Image.asset(
            'assets/images/housev2.png',
            width: 280, // Reduced from 325
            height: 280, // Reduced from 325
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24), // Reduced from 32
          const Text(
            'Save energy and enjoy fresh air by knowing exactly when to open your windows.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24), // Reduced from 32
          const Text(
            'To keep your Home Comfortable and Energy efficient we\'ll need to know a bit about your home to provide accurate recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20), // Add some bottom spacing
        ],
      ),
    );
  }

  Widget _buildHomeOrientationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Smart Window Recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          // Country Selection Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Country',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        ' *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: const InputDecoration(
                        labelText: 'Select your country',
                        labelStyle: TextStyle(color: Colors.black87),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        prefixIcon: Icon(Icons.flag, color: Colors.grey),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'US',
                          child: Row(
                            children: [
                              Text('🇺🇸', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              const Text('United States'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'CA',
                          child: Row(
                            children: [
                              Text('🇨🇦', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              const Text('Canada'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'GB',
                          child: Row(
                            children: [
                              Text('🇬🇧', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              const Text('United Kingdom'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'IE',
                          child: Row(
                            children: [
                              Text('🇮🇪', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              const Text('Ireland'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCountry = value;
                        });
                        print('Selected country: $value');
                      },
                      hint: Row(
                        children: [
                          Text('🌍', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          const Text('Choose your country'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Home Address Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Home Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        ' *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Enter your home address',
                      labelStyle: TextStyle(color: Colors.black87),
                      hintText: '123 Main Street, Toronto ON',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.location_on, color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _address = value.trim();
                      });
                      _fetchAddressSuggestions(value);
                    },
                    onFieldSubmitted: (value) async {
                      final trimmedValue = value.trim();
                      setState(() {
                        _address = trimmedValue;
                      });
                      if (trimmedValue.isNotEmpty && _selectedCoords == null) {
                        final coords = await _fetchPlaceCoordinates(trimmedValue);
                        if (coords != null) {
                          setState(() {
                            _selectedCoords = coords;
                          });
                          _fetchPlaceDetailsAndSuggestOrientation(trimmedValue);
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
                      constraints: const BoxConstraints(maxHeight: 120),
                      margin: const EdgeInsets.only(top: 8.0),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _addressSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _addressSuggestions[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              suggestion,
                              style: const TextStyle(color: Colors.black87, fontSize: 14),
                            ),
                            onTap: () async {
                              final trimmedSuggestion = suggestion.trim();
                              setState(() {
                                _address = trimmedSuggestion;
                                _addressController.text = trimmedSuggestion;
                                _addressSuggestions = [];
                              });
                              final coords = await _fetchPlaceCoordinates(trimmedSuggestion);
                              if (coords != null) {
                                setState(() {
                                  _selectedCoords = coords;
                                });
                              }
                              _fetchPlaceDetailsAndSuggestOrientation(trimmedSuggestion);
                            },
                          );
                        },
                      ),
                    ),
                  if (_selectedCoords != null && _address.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    // Static Map Preview
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400, width: 1),
                          ),
                          child: Builder(
                            builder: (context) {
                              final lat = _selectedCoords!['lat']?.toStringAsFixed(6);
                              final lng = _selectedCoords!['lng']?.toStringAsFixed(6);
                              final mapUrl =
                                  'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=280x140&scale=2&markers=color:red%7C$lat,$lng&key=$kGoogleApiKey';
                              return Image.network(
                                mapUrl,
                                width: 280,
                                height: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 280,
                                  height: 140,
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
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Home Orientation Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Which direction does your home face?',
                          style: TextStyle(
                            fontSize: 20, // Reduced from 22
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        ' *',
                        style: TextStyle(
                          fontSize: 20, // Reduced from 22
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Pick the direction your front door faces — it affects airflow and sunlight.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _showDirectionTooltip(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Manual Orientation Picker
                  Center(
                    child: _OrientationPicker(
                      selected: _selectedOrientation,
                      onChanged: (o) {
                        setState(() {
                          _selectedOrientation = o;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getDirectionIcon(HomeOrientation orientation) {
    switch (orientation) {
      case HomeOrientation.north:
        return Icons.arrow_upward;
      case HomeOrientation.east:
        return Icons.arrow_forward;
      case HomeOrientation.south:
        return Icons.arrow_downward;
      case HomeOrientation.west:
        return Icons.arrow_back;
    }
  }

  Widget _buildWindowConfigPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Stay One Step Ahead',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          
          // Phone mockup with notification
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Phone frame
                Container(
                  width: 180,
                  height: 320,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5),
                      borderRadius: BorderRadius.circular(19),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        // Notification card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.air,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'EasyBreezy',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'now',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Perfect breeze incoming! 🌬️',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Open your windows now to cool down naturally and save energy.',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.black54,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Bottom app elements
                        Container(
                          margin: const EdgeInsets.all(14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: 30,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Get real-time notifications when it\'s the perfect time to open or close your windows — based on wind, temperature, and air quality.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black,
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Whether you\'re at home or away, EasyBreezy keeps your home fresh and energy-efficient with smart, personalized alerts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // CTA Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Request notification permissions
                    _requestNotificationPermissions();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Enable Notifications'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // Skip notifications and complete onboarding
                  _completeOnboarding();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                ),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDotProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentPage 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Future<void> _fetchAddressSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _addressSuggestions = [];
      });
      return;
    }
    setState(() {
      _isLoadingSuggestions = true;
    });
    
    // Build URL with country filtering if a country is selected
    String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&types=address&key=$kGoogleApiKey';
    
    // Add country restriction if country is selected
    if (_selectedCountry != null) {
      url += '&components=country:$_selectedCountry';
    }
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _addressSuggestions = (data['predictions'] as List)
            .map((p) => p['description'] as String)
            .toList();
        _isLoadingSuggestions = false;
      });
    } else {
      setState(() {
        _addressSuggestions = [];
        _isLoadingSuggestions = false;
      });
    }
  }

  Future<Map<String, double>?> _fetchPlaceCoordinates(String address) async {
    // Build URL with country filtering if a country is selected
    String autocompleteUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(address)}&types=address&key=$kGoogleApiKey';
    
    // Add country restriction if country is selected
    if (_selectedCountry != null) {
      autocompleteUrl += '&components=country:$_selectedCountry';
    }
    
    final autocompleteResponse = await http.get(Uri.parse(autocompleteUrl));
    if (autocompleteResponse.statusCode == 200) {
      final data = json.decode(autocompleteResponse.body);
      if (data['predictions'] != null && data['predictions'].isNotEmpty) {
        final placeId = data['predictions'][0]['place_id'];
        final detailsUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$kGoogleApiKey',
        );
        final detailsResponse = await http.get(detailsUrl);
        if (detailsResponse.statusCode == 200) {
          final detailsData = json.decode(detailsResponse.body);
          final location = detailsData['result']?['geometry']?['location'];
          if (location != null) {
            return {
              'lat': location['lat'] as double,
              'lng': location['lng'] as double,
            };
          }
        }
      }
    }
    return null;
  }

  Future<void> _fetchPlaceDetailsAndSuggestOrientation(String address) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(address)}&types=address&key=$kGoogleApiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final predictions = data['predictions'] as List;
      if (predictions.isNotEmpty) {
        final placeId = predictions.first['place_id'];
        final detailsUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$kGoogleApiKey',
        );
        final detailsResponse = await http.get(detailsUrl);
        if (detailsResponse.statusCode == 200) {
          final detailsData = json.decode(detailsResponse.body);
          final location = detailsData['result']?['geometry']?['location'];
          if (location != null) {
            final double lng = location['lng'];
            HomeOrientation suggestedOrientation;
            if (lng > 0) {
              suggestedOrientation = HomeOrientation.east;
            } else if (lng < 0) {
              suggestedOrientation = HomeOrientation.west;
            } else {
              suggestedOrientation = HomeOrientation.north;
            }
            setState(() {
              _selectedOrientation = suggestedOrientation;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Orientation auto-suggested: '
                    '${suggestedOrientation.name[0].toUpperCase()}${suggestedOrientation.name.substring(1)} Facing'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    }
  }

  void _showDirectionTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Why home orientation matters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'The direction your front door faces affects how sunlight enters and how air flows around your building. This helps us give you personalized recommendations for comfort and energy efficiency.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestNotificationPermissions() async {
    // In a real app, you would request notification permissions here
    // For now, we'll just show a success message and complete onboarding
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications enabled! You\'ll receive smart window alerts.'),
        duration: Duration(seconds: 2),
      ),
    );
    
    // Wait a moment for the snackbar to show, then complete onboarding
    await Future.delayed(const Duration(milliseconds: 500));
    _completeOnboarding();
  }

  void _completeOnboarding() {
    // Save configuration and complete onboarding
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    homeProvider.updateHomeOrientation(_selectedOrientation!); // Safe to use ! since we validated it exists
    
    // Save the selected country
    if (_selectedCountry != null) {
      homeProvider.updateCountry(_selectedCountry!);
    }
    
    // Assume all sides have windows since we removed the selection
    final allWindows = {
      WindowDirection.north: true,
      WindowDirection.east: true,
      WindowDirection.south: true,
      WindowDirection.west: true,
    };
    homeProvider.updateWindows(allWindows);
    
    // Ensure we get the latest address from the text controller
    final finalAddress = _addressController.text.trim();
    
    // Save address and coordinates if available
    if (_selectedCoords != null && finalAddress.isNotEmpty) {
      homeProvider.updateAddressWithCoords(
        finalAddress,
        _selectedCoords!['lat'],
        _selectedCoords!['lng'],
      );
    } else if (finalAddress.isNotEmpty) {
      homeProvider.updateAddress(finalAddress);
    }
    
    // Debug print to verify address is being saved
    print('Onboarding: Saving address: "$finalAddress"');
    print('Onboarding: Coordinates: $_selectedCoords');
    
    homeProvider.completeOnboarding();
    
    // Navigate to the main app
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainShell(),
        ),
      );
    }
  }
}

// Orientation Picker widget - Compass Style Layout
class _OrientationPicker extends StatelessWidget {
  final HomeOrientation? selected;
  final ValueChanged<HomeOrientation> onChanged;
  const _OrientationPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          children: [
            // North button (top)
            Positioned(
              top: 0,
              left: 60,
              child: _buildDirectionButton(context, HomeOrientation.north),
            ),
            // East button (right)
            Positioned(
              right: 0,
              top: 60,
              child: _buildDirectionButton(context, HomeOrientation.east),
            ),
            // South button (bottom)
            Positioned(
              bottom: 0,
              left: 60,
              child: _buildDirectionButton(context, HomeOrientation.south),
            ),
            // West button (left)
            Positioned(
              left: 0,
              top: 60,
              child: _buildDirectionButton(context, HomeOrientation.west),
            ),
            // Center compass decoration
            Positioned(
              top: 75,
              left: 75,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Icon(
                  Icons.explore_outlined,
                  color: Colors.grey.shade600,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionButton(BuildContext context, HomeOrientation orientation) {
    final isSelected = orientation == selected;
    
    return GestureDetector(
      onTap: () => onChanged(orientation),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.white,
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? Theme.of(context).primaryColor.withOpacity(0.4)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isSelected ? 8 : 3,
              offset: Offset(0, isSelected ? 3 : 1),
              spreadRadius: isSelected ? 1 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _getDirectionIcon(orientation),
                color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: isSelected ? 14 : 12,
              ),
              child: Text(orientation.name[0].toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDirectionIcon(HomeOrientation orientation) {
    switch (orientation) {
      case HomeOrientation.north:
        return Icons.north;
      case HomeOrientation.east:
        return Icons.east;
      case HomeOrientation.south:
        return Icons.south;
      case HomeOrientation.west:
        return Icons.west;
    }
  }
}