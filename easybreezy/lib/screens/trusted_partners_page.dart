import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TrustedPartnersPage extends StatelessWidget {
  const TrustedPartnersPage({Key? key}) : super(key: key);

  /// Determines if it's currently day time (6 AM to 6 PM)
  bool _isDayTime() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 6 && hour < 18; // Day from 6 AM to 6 PM
  }

  /// Gets the appropriate background image path based on time
  String _getBackgroundImage() {
    return _isDayTime()
        ? 'assets/images/backgrounds/dayv2.png'
        : 'assets/images/backgrounds/night.png';
  }

  /// Gets the appropriate text color based on time to contrast with background
  Color _getTextColor() {
    return _isDayTime() ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getBackgroundImage()),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: _getTextColor()),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Trusted Partners',
                      style: TextStyle(
                        color: _getTextColor(),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: _isDayTime() ? [] : [
                          const Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 3.0,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable list of partners
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    const SizedBox(height: 16),
                    _buildPartnerCard(
                      businessName: 'GreenTech Solutions',
                      description: 'Leading provider of smart home energy management systems and eco-friendly automation solutions.',
                      logoIcon: Icons.energy_savings_leaf,
                      websiteUrl: 'https://example.com/greentech',
                      logoColor: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildPartnerCard(
                      businessName: 'EcoComfort HVAC',
                      description: 'Certified specialists in energy-efficient heating, ventilation, and air conditioning installations.',
                      logoIcon: Icons.ac_unit,
                      websiteUrl: 'https://example.com/ecocomfort',
                      logoColor: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildPartnerCard(
                      businessName: 'Pure Air Quality Co.',
                      description: 'Expert indoor air quality testing and purification solutions for healthier living spaces.',
                      logoIcon: Icons.air,
                      websiteUrl: 'https://example.com/pureair',
                      logoColor: Colors.cyan,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerCard({
    required String businessName,
    required String description,
    required IconData logoIcon,
    required String websiteUrl,
    required Color logoColor,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: logoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: logoColor.withOpacity(0.3), width: 2),
              ),
              child: Icon(
                logoIcon,
                size: 32,
                color: logoColor,
              ),
            ),
            const SizedBox(width: 16),
            // Business info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: logoColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => _launchURL(websiteUrl),
                      child: const Text(
                        'Visit Website',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Handle error - could show a snackbar or dialog
      print('Could not launch $url');
    }
  }
}
