import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/smart_view_screen.dart';
import '../screens/pro_info_screen.dart';
import '../widgets/floating_menu_bar.dart';
import '../services/auto_refresh_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final AutoRefreshService _autoRefreshService = AutoRefreshService();

  final List<Widget> _pages = [
    const HomeScreen(),
    const SmartViewScreen(),
    const SettingsScreen(),
    const ProInfoScreen(), // Link to new Pro/Info page
  ];

  @override
  void initState() {
    super.initState();
    // Update the auto-refresh service context when this shell is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoRefreshService.updateContext(context);
    });
  }

  void _onMenuTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Update auto-refresh service context when switching tabs
    _autoRefreshService.updateContext(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgrounds/dayv2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _pages[_selectedIndex]),
            FloatingMenuBar(
              selectedIndex: _selectedIndex,
              onTap: _onMenuTap,
            ),
          ],
        ),
      ),
    );
  }
}
