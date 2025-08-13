import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to appropriate screen after 3 seconds
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Wait for minimum splash time
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    
    // Wait for HomeProvider to be initialized (load saved data)
    while (!homeProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
    
    // Now check if user has completed initial setup (onboarding + location data)
    final hasCompletedSetup = await homeProvider.hasCompletedInitialSetup();
    
    Widget nextScreen;
    if (hasCompletedSetup) {
      // User has completed setup and has saved data - go to main app
      nextScreen = const MainShell();
    } else if (homeProvider.isOnboardingCompleted) {
      // User completed onboarding but no location data - go to main app (will prompt for location)
      nextScreen = const MainShell();
    } else {
      // User hasn't completed onboarding - go to onboarding
      nextScreen = const OnboardingScreen();
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => nextScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgrounds/loadingBackground.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Top spacer (75% of the screen height)
                const Expanded(
                  flex: 75,
                  child: SizedBox(),
                ),
                
                // Loading indicator section (centered at 75% down)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Spacer before sponsor card
                const Expanded(
                  flex: 25,
                  child: SizedBox(),
                ),
                
                // Bottom section with sponsor card
                Card(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Today's Breeze Sponsor",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Clearview Exteriors — Upgrade your airflow, upgrade your view.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
