import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/home_config.dart';
import '../providers/home_provider.dart';

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
  HomeOrientation _selectedOrientation = HomeOrientation.north;
  final Map<WindowDirection, bool> _selectedWindows = {
    WindowDirection.north: false,
    WindowDirection.east: false,
    WindowDirection.south: false,
    WindowDirection.west: false,
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Save configuration and complete onboarding
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      homeProvider.updateHomeOrientation(_selectedOrientation);
      homeProvider.updateWindows(_selectedWindows);
      homeProvider.completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _totalPages,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentPage > 0
                    ? TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Back'),
                      )
                    : const SizedBox(width: 80),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(_currentPage < _totalPages - 1 ? 'Next' : 'Get Started'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco_outlined,
            size: 100,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to EasyBreezy',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Save energy and enjoy fresh air by knowing exactly when to open your windows.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'We\'ll need to know a bit about your home to provide accurate recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeOrientationPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Which direction does your home face?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This helps us determine how wind and sun affect your home.',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: HomeOrientation.values.map((orientation) {
                final bool isSelected = orientation == _selectedOrientation;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOrientation = orientation;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getDirectionIcon(orientation),
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          orientation.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Which sides of your home have windows?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select all sides that have windows you can open.',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: WindowDirection.values.map((direction) {
                return CheckboxListTile(
                  title: Text(direction.name),
                  subtitle: Text('Windows facing ${direction.name}'),
                  value: _selectedWindows[direction] ?? false,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (bool? value) {
                    setState(() {
                      _selectedWindows[direction] = value ?? false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}