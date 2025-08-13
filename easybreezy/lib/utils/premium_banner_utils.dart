import 'package:flutter/material.dart';
import '../widgets/premium_upgrade_banner.dart';
import '../providers/home_provider.dart';
import 'package:provider/provider.dart';

/// Utility class for testing and managing the premium upgrade banner
class PremiumBannerUtils {
  /// Reset the banner to show again (useful for testing)
  static Future<void> resetBanner() async {
    await PremiumUpgradeBanner.resetBannerState();
  }

  /// Reset premium status and banner (for demo purposes)
  static void resetPremiumStatus(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    homeProvider.resetPremiumStatus();
  }

  /// Simulate premium upgrade (for demo purposes)
  static void simulateUpgrade(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    homeProvider.upgradeToPremium();
  }

  /// Show a debug dialog with banner controls (for testing)
  static void showBannerDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Banner Debug Controls'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Use these controls to test the premium banner:'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await resetBanner();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Banner reset - it will show again')),
                );
              },
              child: const Text('Reset Banner'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                resetPremiumStatus(context);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium status reset')),
                );
              },
              child: const Text('Reset Premium Status'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                simulateUpgrade(context);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium status enabled')),
                );
              },
              child: const Text('Simulate Upgrade'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
