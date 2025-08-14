import 'package:flutter/material.dart';

class ConnectSmartThermostatPage extends StatelessWidget {
  const ConnectSmartThermostatPage({Key? key}) : super(key: key);

  // List of supported thermostat providers
  static const List<Map<String, String>> supportedProviders = [
    {
      'name': 'Google Nest',
      'logo': 'assets/images/thermostat_logos/nest_logo.png',
      'description': 'Connect your Nest Learning Thermostat'
    },
    {
      'name': 'Ecobee',
      'logo': 'assets/images/thermostat_logos/ecobee_logo.png',
      'description': 'Connect your Ecobee Smart Thermostat'
    },
    {
      'name': 'Honeywell',
      'logo': 'assets/images/thermostat_logos/honeywell_logo.png',
      'description': 'Connect your Honeywell Home Thermostat'
    },
    {
      'name': 'SmartThings',
      'logo': 'assets/images/thermostat_logos/smartthings_logo.png',
      'description': 'Connect via Samsung SmartThings'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8), // Easy Breezy background color
      appBar: AppBar(
        title: const Text(
          'Connect Smart Thermostat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF43B3AE), // Easy Breezy primary color
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            
            // Top section: Thermostat illustration
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.thermostat,
                  size: 64,
                  color: Color(0xFF43B3AE),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Middle section: Headline and description
            const Text(
              'Connect your thermostat',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Sync your smart thermostat with Easy Breezy to optimize your indoor comfort and save energy.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // Provider list section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose your thermostat brand:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Dynamic provider list
                ...supportedProviders.map((provider) => 
                  _buildProviderCard(context, provider)
                ).toList(),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Info button at the bottom
            Center(
              child: TextButton.icon(
                onPressed: () => _showInfoDialog(context),
                icon: Icon(
                  Icons.info_outline,
                  color: const Color(0xFF43B3AE),
                ),
                label: const Text(
                  'Why connect my thermostat?',
                  style: TextStyle(
                    color: Color(0xFF43B3AE),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context, Map<String, String> provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Provider logo placeholder (using icon for now)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF43B3AE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.thermostat_outlined,
                  size: 24,
                  color: Color(0xFF43B3AE),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Provider info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider['name']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider['description']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Connect button
              ElevatedButton.icon(
                onPressed: () => _startOAuth(context, provider['name']!),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Connect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43B3AE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startOAuth(BuildContext context, String providerName) {
    // OAuth flow placeholder function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.link,
                color: const Color(0xFF43B3AE),
              ),
              const SizedBox(width: 8),
              Text('Connect $providerName'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You will be redirected to $providerName to authorize the connection.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F9F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF43B3AE).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          size: 16,
                          color: const Color(0xFF43B3AE),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Secure Connection',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Easy Breezy uses industry-standard OAuth 2.0 for secure authentication.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Simulate OAuth flow
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$providerName OAuth flow would start here'),
                    backgroundColor: const Color(0xFF43B3AE),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43B3AE),
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.info,
                color: Color(0xFF43B3AE),
              ),
              SizedBox(width: 8),
              Text('Why Connect Your Thermostat?'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBenefitItem(
                  Icons.savings,
                  'Save Energy & Money',
                  'Automatic optimization can save 10-23% on heating and cooling costs.',
                ),
                const SizedBox(height: 16),
                _buildBenefitItem(
                  Icons.auto_awesome,
                  'Smart Automation',
                  'Weather-based scheduling and peak demand avoidance.',
                ),
                const SizedBox(height: 16),
                _buildBenefitItem(
                  Icons.home,
                  'Enhanced Comfort',
                  'Maintain optimal temperature and humidity levels automatically.',
                ),
                const SizedBox(height: 16),
                _buildBenefitItem(
                  Icons.timeline,
                  'Usage Insights',
                  'Detailed analytics on your energy consumption patterns.',
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9F8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF43B3AE).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.privacy_tip,
                            size: 16,
                            color: const Color(0xFF43B3AE),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Privacy & Security',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Data is encrypted and stored securely\n'
                        '• You can disconnect at any time\n'
                        '• We only access necessary thermostat data\n'
                        '• No personal information is shared with third parties',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43B3AE),
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: const Color(0xFF43B3AE),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
