import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/home_config.dart';
import '../providers/home_provider.dart';
import '../widgets/enhanced_location_picker_widget.dart';
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
  List<WindowDirection> _selectedWindows = [];
  bool _locationSetupComplete = false; // Track when enhanced location picker is complete
  
  // Address-related state variables
  late String _address;
  late TextEditingController _addressController;
  String? _selectedCountry;
  static const String kGoogleApiKey = 'AIzaSyBmZfcpnFKGRr2uzcL3ayXxUN-_fX6fy7s';
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
      // Check if enhanced location setup is complete
      else if (!_locationSetupComplete) {
        canProceed = false;
        errorMessage = 'Please complete your location setup with satellite view';
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

  // Callback for when enhanced location picker completes
  void _onLocationSelected(String address, Map<String, double> coords, HomeOrientation orientation, List<WindowDirection> windows) {
    setState(() {
      _address = address;
      _selectedCoords = coords;
      _selectedOrientation = orientation;
      _selectedWindows = windows;
      _locationSetupComplete = true;
    });
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
          
          // Enhanced Location Setup Section
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
                        'Location & Orientation Setup',
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
                  const SizedBox(height: 8),
                  const Text(
                    'Use satellite view to precisely locate your home and detect window orientations automatically.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Enhanced Location Picker
                  Container(
                    height: 500, // Set a fixed height for the picker
                    child: EnhancedLocationPickerWidget(
                      initialAddress: _address.isNotEmpty ? _address : null,
                      initialOrientation: _selectedOrientation,
                      initialCoords: _selectedCoords,
                      selectedCountry: _selectedCountry,
                      onLocationSelected: _onLocationSelected,
                      showTitle: false, // Don't show title since we have our own
                    ),
                  ),
                  if (_locationSetupComplete) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Location setup complete! Address: $_address, Orientation: ${_selectedOrientation?.name.toUpperCase()}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
    
    // Convert list of selected windows to map format for provider
    final windowsMap = {
      WindowDirection.north: _selectedWindows.contains(WindowDirection.north),
      WindowDirection.east: _selectedWindows.contains(WindowDirection.east),
      WindowDirection.south: _selectedWindows.contains(WindowDirection.south),
      WindowDirection.west: _selectedWindows.contains(WindowDirection.west),
    };
    homeProvider.updateWindows(windowsMap);
    
    // Use the address from enhanced location picker
    if (_selectedCoords != null && _address.isNotEmpty) {
      homeProvider.updateAddressWithCoords(
        _address,
        _selectedCoords!['lat'],
        _selectedCoords!['lng'],
      );
    } else if (_address.isNotEmpty) {
      homeProvider.updateAddress(_address);
    }
    
    // Debug print to verify configuration is being saved
    print('Onboarding: Saving address: "$_address"');
    print('Onboarding: Coordinates: $_selectedCoords');
    print('Onboarding: Orientation: ${_selectedOrientation?.name}');
    print('Onboarding: Windows: $_selectedWindows');
    
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