import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({Key? key}) : super(key: key);

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
        child: Column(
          children: [
            // App Bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Legal Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Main Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            Icons.gavel,
                            color: Colors.blue.shade600,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Legal Terms & Agreements',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: September 2, 2025',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Legal Sections
                      _buildSection(
                        'Terms of Service',
                        'By using Easy Breezy, you agree to these terms of service. '
                        'Easy Breezy is a smart weather and home comfort app that provides real-time weather data, '
                        'energy efficiency recommendations, and smart home integrations. '
                        'You must use the app in accordance with all applicable laws and regulations. '
                        'We reserve the right to terminate access for violations of these terms.',
                        Icons.description,
                        Colors.blue.shade600,
                      ),
                      
                      _buildSection(
                        'Privacy Policy',
                        'We respect your privacy and are committed to protecting your personal data. '
                        'Easy Breezy collects location data to provide accurate weather forecasts and personalized recommendations. '
                        'We use this information solely to improve our services and provide you with relevant content. '
                        'Your data is encrypted and stored securely. You can request data deletion at any time through app settings.',
                        Icons.privacy_tip,
                        Colors.green.shade600,
                      ),
                      
                      _buildSection(
                        'Data Collection & Usage',
                        'Easy Breezy collects the following information to provide our services:\n'
                        '• Location data for weather forecasts\n'
                        '• Home configuration for energy recommendations\n'
                        '• Smart thermostat data (with your explicit consent)\n'
                        '• Usage analytics to improve the app experience\n\n'
                        'All data is processed locally when possible and shared only with necessary third-party services.',
                        Icons.data_usage,
                        Colors.orange.shade600,
                      ),
                      
                      _buildSection(
                        'Third-Party Integrations',
                        'Easy Breezy integrates with various third-party services:\n'
                        '• OpenWeatherMap for weather data\n'
                        '• Google Nest for smart thermostat control\n'
                        '• Ecobee for energy management\n'
                        '• Honeywell and SmartThings for device connectivity\n\n'
                        'Each integration is subject to the respective service\'s privacy policies and terms.',
                        Icons.integration_instructions,
                        Colors.purple.shade600,
                      ),
                      
                      _buildSection(
                        'Premium Subscription',
                        'Premium features are available for \$1.99/month and include:\n'
                        '• Advanced smart thermostat integration\n'
                        '• Detailed carbon footprint analytics\n'
                        '• Priority customer support\n'
                        '• Extended weather forecasts\n\n'
                        'Subscriptions auto-renew monthly and can be cancelled anytime through your device\'s app store settings.',
                        Icons.star,
                        Colors.amber.shade600,
                      ),
                      
                      _buildSection(
                        'Disclaimers',
                        'Weather data and energy recommendations are provided for informational purposes only. '
                        'Easy Breezy does not guarantee the accuracy of weather predictions or energy savings calculations. '
                        'Users are responsible for verifying critical weather information and ensuring smart home device safety. '
                        'Actual energy savings may vary based on individual usage patterns and local conditions.',
                        Icons.warning,
                        Colors.red.shade600,
                      ),
                      
                      _buildSection(
                        'Contact Information',
                        'For questions about these legal terms or our privacy practices:\n\n'
                        '📧 Email: legal@easybreezy.app\n'
                        '🔒 Privacy: privacy@easybreezy.app\n'
                        '🆘 Support: support@easybreezy.app\n\n'
                        'Easy Breezy App Development Team\n'
                        '© 2025 Easy Breezy. All rights reserved.',
                        Icons.contact_mail,
                        Colors.indigo.shade600,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Footer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Important Notice',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'These terms may be updated periodically. Continued use of the app after changes constitutes acceptance of new terms. '
                              'We recommend reviewing this page regularly for updates.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
