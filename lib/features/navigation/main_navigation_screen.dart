import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../dashboard/presentation/screens/home_dashboard_screen.dart';
import '../garage/presentation/screens/garage_screen.dart';
import '../maintenance/presentation/screens/maintenance_screen.dart';
import '../ride_tracking/presentation/screens/ride_tracking_screen.dart';
import '../settings/presentation/screens/settings_screen.dart';

/// Top-level Navigation Bar holding the 5 persistent destinations (PRD Section 6 & DSS Section 9)
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(
        onNavigateToTracking: () => _onTabSelected(1),
        onNavigateToMaintenance: () => _onTabSelected(2),
      ),
      const RideTrackingScreen(),
      const MaintenanceScreen(),
      const GarageScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1.0),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Dasbor',
            ),
            NavigationDestination(
              icon: Icon(Icons.navigation_outlined),
              selectedIcon: Icon(Icons.navigation_rounded),
              label: 'Pelacakan',
            ),
            NavigationDestination(
              icon: Icon(Icons.health_and_safety_outlined),
              selectedIcon: Icon(Icons.health_and_safety_rounded),
              label: 'Kesehatan',
            ),
            NavigationDestination(
              icon: Icon(Icons.garage_outlined),
              selectedIcon: Icon(Icons.garage_rounded),
              label: 'Garasi',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
