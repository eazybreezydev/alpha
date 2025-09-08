import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../services/firebase_messaging_service.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize notification provider when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            children: [
              // Main toggle
              _buildMainNotificationToggle(notificationProvider),
              
              if (notificationProvider.notificationsEnabled) ...[
                const Divider(),
                
                // Ventilation Alerts Section
                _buildSectionHeader('🌬️ Ventilation Alerts'),
                _buildNotificationTile(
                  'Open Windows Alert',
                  'Get notified when conditions are perfect for opening windows',
                  notificationProvider.openWindowsAlert,
                  notificationProvider.toggleOpenWindowsAlert,
                  NotificationType.openWindowsAlert,
                  notificationProvider,
                ),
                _buildNotificationTile(
                  'Close Windows Alert',
                  'Get notified when you should close windows',
                  notificationProvider.closeWindowsAlert,
                  notificationProvider.toggleCloseWindowsAlert,
                  NotificationType.closeWindowsAlert,
                  notificationProvider,
                ),
                _buildNotificationTile(
                  'Wind Alignment Alert',
                  'Get notified when wind direction is optimal for your home',
                  notificationProvider.windAlignmentAlert,
                  notificationProvider.toggleWindAlignmentAlert,
                  NotificationType.windAlignmentAlert,
                  notificationProvider,
                ),
                
                const Divider(),
                
                // Weather Warnings Section
                _buildSectionHeader('⛈️ Weather Warnings'),
                _buildNotificationTile(
                  'Rain Alert',
                  'Get notified before rain arrives',
                  notificationProvider.rainAlert,
                  notificationProvider.toggleRainAlert,
                  NotificationType.rainAlert,
                  notificationProvider,
                ),
                _buildNotificationTile(
                  'Storm Warning',
                  'Get notified of severe weather approaching',
                  notificationProvider.stormWarning,
                  notificationProvider.toggleStormWarning,
                  NotificationType.stormWarning,
                  notificationProvider,
                ),
                _buildNotificationTile(
                  'High Wind Advisory',
                  'Get notified of strong winds',
                  notificationProvider.highWindAdvisory,
                  notificationProvider.toggleHighWindAdvisory,
                  NotificationType.highWindAdvisory,
                  notificationProvider,
                ),
                
                const Divider(),
                
                // Forecast-Based Notifications Section
                _buildSectionHeader('🔮 Smart Forecasting'),
                _buildNotificationTile(
                  'Ventilation Opportunity',
                  'Get notified of perfect natural cooling windows',
                  notificationProvider.ventilationOpportunity,
                  notificationProvider.toggleVentilationOpportunity,
                  NotificationType.ventilationOpportunity,
                  notificationProvider,
                ),
                _buildNotificationTile(
                  'Poor Air Quality',
                  'Get notified when air quality is poor',
                  notificationProvider.poorAirQuality,
                  notificationProvider.togglePoorAirQuality,
                  NotificationType.poorAirQuality,
                  notificationProvider,
                ),
                _buildNotificationTile(
                  'High Pollen Alert',
                  'Get notified when pollen levels are high',
                  notificationProvider.highPollenAlert,
                  notificationProvider.toggleHighPollenAlert,
                  NotificationType.highPollenAlert,
                  notificationProvider,
                ),
                _buildNotificationTile(
                  'Smoke Advisory',
                  'Get notified of wildfire smoke in your area',
                  notificationProvider.smokeAdvisory,
                  notificationProvider.toggleSmokeAdvisory,
                  NotificationType.smokeAdvisory,
                  notificationProvider,
                ),
                
                const Divider(),
                
                // Daily Summary Section
                _buildSectionHeader('📊 Daily Reports'),
                _buildNotificationTile(
                  'Morning Summary',
                  'Daily forecast and energy savings summary',
                  notificationProvider.dailyMorningSummary,
                  notificationProvider.toggleDailyMorningSummary,
                  NotificationType.dailyMorningSummary,
                  notificationProvider,
                ),
                _buildNotificationTile(
                  'Weekly Report',
                  'Weekly efficiency and savings report',
                  notificationProvider.weeklyReport,
                  notificationProvider.toggleWeeklyReport,
                  NotificationType.weeklyReport,
                  notificationProvider,
                ),
                
                const Divider(),
                
                // System & Efficiency Section
                _buildSectionHeader('⚙️ System & Tips'),
                _buildNotificationTile(
                  'Energy Tips',
                  'Smart tips to improve efficiency',
                  notificationProvider.energyTip,
                  notificationProvider.toggleEnergyTip,
                  NotificationType.energyTip,
                  notificationProvider,
                ),
                _buildNotificationTile(
                  'Cost Savings',
                  'Updates on your money savings',
                  notificationProvider.costSaving,
                  notificationProvider.toggleCostSaving,
                  NotificationType.costSaving,
                  notificationProvider,
                ),
                _buildNotificationTile(
                  'System Status',
                  'EasyBreezy system health updates',
                  notificationProvider.systemStatus,
                  notificationProvider.toggleSystemStatus,
                  NotificationType.systemStatus,
                  notificationProvider,
                ),
                _buildNotificationTile(
                  'Maintenance Reminders',
                  'Reminders for home maintenance tasks',
                  notificationProvider.maintenanceReminder,
                  notificationProvider.toggleMaintenanceReminder,
                  NotificationType.maintenanceReminder,
                  notificationProvider,
                ),
                
                const Divider(),
                
                // FCM Token info (for debugging) - always show, even if null
                _buildTokenInfo(notificationProvider.fcmToken ?? 'Loading token...'),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainNotificationToggle(NotificationProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: provider.notificationsEnabled 
            ? Colors.green.withOpacity(0.1) 
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: provider.notificationsEnabled 
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                provider.notificationsEnabled 
                    ? Icons.notifications_active 
                    : Icons.notifications_off,
                color: provider.notificationsEnabled ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EasyBreezy Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      provider.notificationsEnabled 
                          ? 'Receive smart alerts to optimize your home\'s comfort and efficiency'
                          : 'Notifications are disabled',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Switch(
                value: provider.notificationsEnabled,
                onChanged: provider.toggleNotifications,
                activeColor: Colors.green,
              ),
            ],
          ),
          if (!provider.notificationsEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await provider.openNotificationSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open System Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    NotificationType testType,
    NotificationProvider provider,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Test button
          IconButton(
            onPressed: () => provider.sendTestNotification(testType),
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Send test notification',
            iconSize: 20,
          ),
          // Toggle switch
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildTokenInfo(String token) {
    return ExpansionTile(
      title: const Text('🔧 Developer Info'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FCM Token:',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, provider, child) {
                      return TextButton.icon(
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Refreshing FCM token...')),
                          );
                          await provider.refreshFCMToken();
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  token,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This token is used to send notifications to this device.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
