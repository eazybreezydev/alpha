import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_messaging_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String? _fcmToken;
  List<NotificationData> _receivedNotifications = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadToken();
    _setupNotificationListeners();
  }

  void _loadToken() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('🔍 Loading FCM token for notification test screen...');
      
      // Check if Firebase is initialized
      if (!FirebaseMessagingService.isInitialized()) {
        print('❌ Firebase not initialized');
        setState(() {
          _fcmToken = 'Firebase not initialized';
          _isLoading = false;
        });
        return;
      }
      
      // Try to get token with retries
      final token = await FirebaseMessagingService.getToken(maxRetries: 5);
      if (token != null && token.isNotEmpty) {
        print('✅ FCM token loaded successfully');
        setState(() {
          _fcmToken = token;
          _isLoading = false;
        });
      } else {
        print('⚠️ Real FCM token failed, using test token');
        final testToken = await FirebaseMessagingService.getTestToken();
        setState(() {
          _fcmToken = testToken;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading FCM token: $e');
      setState(() {
        _fcmToken = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _setupNotificationListeners() {
    FirebaseMessagingService.setNotificationListeners(
      onReceived: (NotificationData data) {
        setState(() {
          _receivedNotifications.insert(0, data);
        });
        _showSnackBar('📱 Received: ${data.title}', Colors.blue);
      },
      onTapped: (NotificationData data) {
        _showSnackBar('👆 Tapped: ${data.title}', Colors.green);
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showNotificationDetailsDialog(NotificationData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notification Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${data.type.toString().split('.').last}'),
            const SizedBox(height: 8),
            Text('Title: ${data.title}'),
            const SizedBox(height: 8),
            Text('Body: ${data.body}'),
            const SizedBox(height: 8),
            Text('Time: ${data.timestamp.toLocal()}'),
            if (data.data.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Data: ${data.data}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Helper method to get a darker version of a color
  Color _getDarkerColor(Color color) {
    // Create a darker version by reducing the lightness
    HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }

  Widget _buildInstructionSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNotificationCategory(String title, List<NotificationType> types, Color color) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _getColorDark(color),
        ),
      ),
      children: types.map((type) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => FirebaseMessagingService.sendTestNotification(type),
            icon: Icon(_getNotificationIcon(type), size: 18),
            label: Text(
              _getNotificationLabel(type),
              style: const TextStyle(fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getDarkerColor(color),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Testing'),
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FCM Token Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📱 FCM Token',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _fcmToken ?? 'Loading...',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _fcmToken != null ? () => _copyTokenToClipboard() : null,
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _printTokenToConsole(),
                          icon: const Icon(Icons.terminal, size: 16),
                          label: const Text('Print'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use this token to send targeted notifications from Firebase Console',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Notifications Section - Organized by Category
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Production-Ready Test Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Ventilation Alerts Section
                    _buildNotificationCategory(
                      '🌬️ Ventilation Alerts',
                      [
                        NotificationType.openWindowsAlert,
                        NotificationType.closeWindowsAlert,
                        NotificationType.windAlignmentAlert,
                      ],
                      Colors.green,
                    ),
                    
                    // Weather Warnings Section
                    _buildNotificationCategory(
                      '⛈️ Weather Warnings',
                      [
                        NotificationType.rainAlert,
                        NotificationType.stormWarning,
                        NotificationType.highWindAdvisory,
                      ],
                      Colors.orange,
                    ),
                    
                    // Forecast-Based Notifications Section
                    _buildNotificationCategory(
                      '📋 Forecast-Based Alerts',
                      [
                        NotificationType.ventilationOpportunity,
                        NotificationType.poorAirQuality,
                        NotificationType.highPollenAlert,
                        NotificationType.smokeAdvisory,
                      ],
                      Colors.blue,
                    ),
                    
                    // Daily Summary Section
                    _buildNotificationCategory(
                      '📊 Daily & Weekly Reports',
                      [
                        NotificationType.dailyMorningSummary,
                        NotificationType.weeklyReport,
                      ],
                      Colors.purple,
                    ),
                    
                    // System & Efficiency Section
                    _buildNotificationCategory(
                      '⚙️ System & Efficiency',
                      [
                        NotificationType.energyTip,
                        NotificationType.costSaving,
                        NotificationType.systemStatus,
                        NotificationType.maintenanceReminder,
                      ],
                      Colors.teal,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Production Testing Guide',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildInstructionSection('🔬 Local Testing', [
                      'Tap any notification above to test locally',
                      'Test different categories to verify messaging',
                      'Check notification appears in system tray',
                      'Verify sound, vibration, and visual style',
                    ]),
                    
                    _buildInstructionSection('☁️ Remote Testing (Firebase)', [
                      'Copy FCM token from above',
                      'Go to Firebase Console → Cloud Messaging',
                      'Send targeted test with custom data:',
                      '  • type: "openWindowsAlert"',
                      '  • temperature: "68"',
                      '  • windSpeed: "8"',
                    ]),
                    
                    _buildInstructionSection('📱 Scenario Testing', [
                      'Foreground: App open and active',
                      'Background: App minimized/in background',
                      'Terminated: App completely closed',
                      'Notification tap: Verify app opens correctly',
                    ]),
                    
                    _buildInstructionSection('⚙️ Settings Integration', [
                      'Go to Settings → Notifications',
                      'Toggle different notification types',
                      'Test that disabled notifications don\'t appear',
                      'Verify frequency settings (1h, 3h, 6h)',
                    ]),
                    
                    _buildInstructionSection('🎯 Production Checklist', [
                      'Test all 17 notification types',
                      'Verify messaging matches user expectations',
                      'Test with real weather data integration',
                      'Check notification timing and frequency',
                      'Validate user preference respect',
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Received Notifications Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📬 Received Notifications (${_receivedNotifications.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_receivedNotifications.isEmpty)
                      const Text(
                        'No notifications received yet. Try sending a test notification!',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ..._receivedNotifications.take(5).map((notification) => 
                        ListTile(
                          leading: Icon(_getNotificationIcon(notification.type)),
                          title: Text(notification.title),
                          subtitle: Text(notification.body),
                          trailing: Text(
                            '${notification.timestamp.hour}:${notification.timestamp.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () => _showNotificationDetailsDialog(notification),
                        ),
                      ),
                    if (_receivedNotifications.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Showing 5 of ${_receivedNotifications.length} notifications',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      // Ventilation Alerts
      case NotificationType.openWindowsAlert:
        return Icons.sensor_window;
      case NotificationType.closeWindowsAlert:
        return Icons.sensor_door;
      case NotificationType.windAlignmentAlert:
        return Icons.explore;
      
      // Weather Warnings
      case NotificationType.rainAlert:
        return Icons.water_drop;
      case NotificationType.stormWarning:
        return Icons.thunderstorm;
      case NotificationType.highWindAdvisory:
        return Icons.air;
      
      // Forecast-Based Notifications
      case NotificationType.ventilationOpportunity:
        return Icons.stars;
      case NotificationType.poorAirQuality:
        return Icons.masks;
      case NotificationType.highPollenAlert:
        return Icons.local_florist;
      case NotificationType.smokeAdvisory:
        return Icons.smoke_free;
      
      // Daily Summary
      case NotificationType.dailyMorningSummary:
        return Icons.wb_sunny;
      case NotificationType.weeklyReport:
        return Icons.bar_chart;
      
      // System & Efficiency
      case NotificationType.energyTip:
        return Icons.lightbulb;
      case NotificationType.costSaving:
        return Icons.attach_money;
      case NotificationType.systemStatus:
        return Icons.settings;
      case NotificationType.maintenanceReminder:
        return Icons.build;
    }
  }

  String _getNotificationLabel(NotificationType type) {
    switch (type) {
      // Ventilation Alerts
      case NotificationType.openWindowsAlert:
        return 'Open Windows Alert';
      case NotificationType.closeWindowsAlert:
        return 'Close Windows Alert';
      case NotificationType.windAlignmentAlert:
        return 'Wind Alignment Alert';
      
      // Weather Warnings
      case NotificationType.rainAlert:
        return 'Rain Alert';
      case NotificationType.stormWarning:
        return 'Storm Warning';
      case NotificationType.highWindAdvisory:
        return 'High Wind Advisory';
      
      // Forecast-Based Notifications
      case NotificationType.ventilationOpportunity:
        return 'Ventilation Opportunity';
      case NotificationType.poorAirQuality:
        return 'Poor Air Quality';
      case NotificationType.highPollenAlert:
        return 'High Pollen Alert';
      case NotificationType.smokeAdvisory:
        return 'Smoke Advisory';
      
      // Daily Summary
      case NotificationType.dailyMorningSummary:
        return 'Daily Morning Summary';
      case NotificationType.weeklyReport:
        return 'Weekly Report';
      
      // System & Efficiency
      case NotificationType.energyTip:
        return 'Energy Tip';
      case NotificationType.costSaving:
        return 'Cost Savings';
      case NotificationType.systemStatus:
        return 'System Status';
      case NotificationType.maintenanceReminder:
        return 'Maintenance Reminder';
    }
  }

  Color _getNotificationColor(NotificationType type) {
    // Group colors by category
    switch (type) {
      // Ventilation Alerts - Green
      case NotificationType.openWindowsAlert:
      case NotificationType.closeWindowsAlert:
      case NotificationType.windAlignmentAlert:
        return Colors.green;
      
      // Weather Warnings - Orange/Red
      case NotificationType.rainAlert:
      case NotificationType.stormWarning:
      case NotificationType.highWindAdvisory:
        return Colors.orange;
      
      // Forecast-Based - Blue
      case NotificationType.ventilationOpportunity:
      case NotificationType.poorAirQuality:
      case NotificationType.highPollenAlert:
      case NotificationType.smokeAdvisory:
        return Colors.blue;
      
      // Daily Summary - Purple
      case NotificationType.dailyMorningSummary:
      case NotificationType.weeklyReport:
        return Colors.purple;
      
      // System & Efficiency - Teal
      case NotificationType.energyTip:
      case NotificationType.costSaving:
      case NotificationType.systemStatus:
      case NotificationType.maintenanceReminder:
        return Colors.teal;
    }
  }

  Color _getColorDark(Color color) {
    // Handle colors that don't have shade700
    if (color == Colors.orange) return Colors.orange.shade700;
    if (color == Colors.green) return Colors.green.shade700;
    if (color == Colors.blue) return Colors.blue.shade700;
    if (color == Colors.purple) return Colors.purple.shade700;
    if (color == Colors.teal) return Colors.teal.shade700;
    if (color == Colors.indigo) return Colors.indigo.shade700;
    if (color == Colors.amber) return Colors.amber.shade700;
    if (color == Colors.red) return Colors.red.shade700;
    
    // For custom colors or colors without shades, darken manually
    return Color.lerp(color, Colors.black, 0.3) ?? color;
  }

  void _printTokenToConsole() {
    if (_fcmToken != null) {
      print('🔑 FCM TOKEN FOR FIREBASE CONSOLE:');
      print('=====================================');
      print(_fcmToken!);
      print('=====================================');
      _showSnackbar('🖨️ Token printed to console - check your debug output');
    }
  }

  Future<void> _copyTokenToClipboard() async {
    if (_fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ FCM Token copied to clipboard!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
