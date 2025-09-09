import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../providers/smart_home_provider.dart';
import '../widgets/premium_upgrade_banner.dart';
import 'trusted_partners_page.dart';
import 'legal_screen.dart';
import 'feedback_screen.dart';

class ProInfoScreen extends StatelessWidget {
  const ProInfoScreen({Key? key}) : super(key: key);

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
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, _) {
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
                // Sticky Premium Upgrade Banner (only show for non-premium users)
                if (!homeProvider.isPremiumUser)
                  SafeArea(
                    bottom: false,
                    child: PremiumUpgradeBanner(
                      onUpgradeTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Upgrade to Premium'),
                            content: const Text(
                              'Unlock advanced energy insights, detailed comfort analytics, and personalized recommendations to maximize your savings!',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Maybe Later'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Simulate premium upgrade for demo
                                  homeProvider.upgradeToPremium();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Welcome to Premium! 🎉'),
                                      backgroundColor: Colors.green.shade600,
                                    ),
                                  );
                                },
                                child: const Text('Upgrade Now'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                // Main content
                Expanded(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0, left: 16, right: 16, bottom: 60),
                      child: SingleChildScrollView(
                        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProInfoButton(
              label: 'Trusted Partners',
              icon: Icons.handshake,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TrustedPartnersPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            ProInfoButton(
              label: 'Feedback',
              icon: Icons.feedback,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            ProInfoButton(
              label: 'What is Easy Breezy?',
              icon: Icons.info_outline,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('What is Easy Breezy?'),
                    content: const Text('Easy Breezy is a smart weather and home comfort app that helps you decide when to open your windows, track air quality, and get personalized tips for a greener lifestyle.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            ProInfoButton(
              label: 'Unlock Pro Features',
              icon: Icons.lock_open,
              onPressed: () {
                // TODO: Implement pro unlock logic
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pro features coming soon!')));
              },
            ),
            const SizedBox(height: 18),
            ProInfoButton(
              label: 'Share With Friends',
              icon: Icons.share,
              onPressed: () {
                // TODO: Implement share logic
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share feature coming soon!')));
              },
            ),
            const SizedBox(height: 18),
            ProInfoButton(
              label: 'Shop Smart Things',
              icon: Icons.devices_other,
              onPressed: () {
                // TODO: Implement smart things logic
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Smart Things integration coming soon!')));
              },
            ),
            const SizedBox(height: 18),
            ProInfoButton(
              label: 'Connect My AC',
              icon: Icons.ac_unit,
              onPressed: () {
                _showSmartHomeConnectionDialog(context);
              },
            ),
            const SizedBox(height: 18),
            ProInfoButton(
              label: "Today's Green Tip",
              icon: Icons.eco,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Today's Green Tip"),
                    content: const Text('Open your windows for fresh air instead of running the AC whenever possible. Small changes add up!'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            ProInfoButton(
              label: 'Legal',
              icon: Icons.gavel,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LegalScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        ),
        ),
        ),
          ),
        ],
      ),
    ),
  );
      },
    );
  }

  void _showSmartHomeConnectionDialog(BuildContext context) {
    final smartHomeProvider = Provider.of<SmartHomeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => Consumer<SmartHomeProvider>(
        builder: (context, provider, _) {
          return AlertDialog(
            title: const Text('Connect Your AC'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Connect your smart home provider to control your AC through Easy Breezy.'),
                const SizedBox(height: 16),
                
                // SmartThings option
                ListTile(
                  leading: Icon(
                    Icons.devices_other,
                    color: provider.providerConnections['smartthings'] == true 
                        ? Colors.green 
                        : Colors.grey,
                  ),
                  title: const Text('SmartThings'),
                  subtitle: Text(
                    provider.providerConnections['smartthings'] == true 
                        ? 'Connected' 
                        : 'Not connected',
                  ),
                  trailing: provider.providerConnections['smartthings'] == true 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  onTap: provider.isLoading ? null : () {
                    if (provider.providerConnections['smartthings'] == true) {
                      provider.disconnectProvider('smartthings');
                    } else {
                      provider.connectProvider(context, 'smartthings');
                    }
                  },
                ),
                
                // Google Home option
                ListTile(
                  leading: Icon(
                    Icons.home,
                    color: provider.providerConnections['googlehome'] == true 
                        ? Colors.green 
                        : Colors.grey,
                  ),
                  title: const Text('Google Home'),
                  subtitle: Text(
                    provider.providerConnections['googlehome'] == true 
                        ? 'Connected' 
                        : 'Not connected',
                  ),
                  trailing: provider.providerConnections['googlehome'] == true 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  onTap: provider.isLoading ? null : () {
                    if (provider.providerConnections['googlehome'] == true) {
                      provider.disconnectProvider('googlehome');
                    } else {
                      provider.connectProvider(context, 'googlehome');
                    }
                  },
                ),
                
                if (provider.hasAvailableDevices) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Found ${provider.devices.length} AC device(s)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
                
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
            actions: [
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              if (provider.hasConnectedProviders)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    provider.refresh();
                  },
                  child: const Text('Refresh Devices'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ProInfoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const ProInfoButton({Key? key, required this.label, required this.icon, required this.onPressed}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        icon: Icon(icon, size: 28, color: Colors.black),
        label: Text(label, style: const TextStyle(color: Colors.black)),
        onPressed: onPressed,
      ),
    );
  }
}
