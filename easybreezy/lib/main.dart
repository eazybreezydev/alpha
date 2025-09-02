import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'providers/home_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/smart_home_provider.dart';
import 'providers/local_ads_provider.dart';
import 'providers/quick_tips_provider.dart';
import 'screens/splash_screen.dart'; // Import SplashScreen
import 'utils/notification_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/auto_refresh_service.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Background message received: ${message.notification?.title}');
  // Handle background notification logic here
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test Firebase initialization with detailed logging
  print('=== Starting Firebase initialization ===');
  print('Platform: iOS/Android');
  print('Flutter version check passed');
  
  try {
    // Try to initialize Firebase with more detailed error handling
    print('About to call Firebase.initializeApp()...');
    
    final app = await Firebase.initializeApp();
    print('✅ Firebase initialized successfully!');
    print('App name: ${app.name}');
    print('Project ID: ${app.options.projectId}');
    print('API Key: ${app.options.apiKey}');
    
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ Background message handler set');
    
    // Initialize Firebase Messaging Service
    try {
      print('Initializing Firebase Messaging Service...');
      await FirebaseMessagingService.initialize();
      print('✅ Firebase Messaging Service initialized');
      
    } catch (messagingError) {
      print('❌ Firebase Messaging error: $messagingError');
    }
    
  } catch (firebaseError) {
    print('❌ Firebase Core initialization failed: $firebaseError');
    print('Error type: ${firebaseError.runtimeType}');
    
    // Check if GoogleService-Info.plist is accessible
    print('Checking bundle resources...');
  }
  
  try {
    // Initialize notifications
    await NotificationService().init();
    print('Notification service initialized successfully');
  } catch (e) {
    print('Notification service initialization error: $e');
    // Continue without notifications if initialization fails
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => SmartHomeProvider()),
        ChangeNotifierProvider(create: (_) => LocalAdsProvider()),
        ChangeNotifierProvider(create: (_) => QuickTipsProvider()),
      ],
      child: MaterialApp(
        title: 'EasyBreezy',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const SplashScreen(), // Start with SplashScreen
      ),
    );
  }
}