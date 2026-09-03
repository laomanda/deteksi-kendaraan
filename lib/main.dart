import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/hive_registrar.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/main_navigation_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize binary Hive database and register TypeAdapters (PRD Section 5.1 & 13)
  await HiveRegistrar.init();

  // Initialize local notifications
  await NotificationService.init();

  // Check if any vehicle exists in local storage
  final hasVehicles = HiveRegistrar.vehiclesBox.isNotEmpty;
  final hasActiveRide = HiveRegistrar.settingsBox.get('active_ride_session') != null;

  runApp(
    ProviderScope(
      child: RideCareApp(
        hasInitialVehicle: hasVehicles,
        initialNavIndex: hasActiveRide ? 1 : 0,
      ),
    ),
  );
}

class RideCareApp extends StatelessWidget {
  final bool hasInitialVehicle;
  final int initialNavIndex;

  const RideCareApp({
    super.key,
    required this.hasInitialVehicle,
    this.initialNavIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: hasInitialVehicle
          ? MainNavigationScreen(initialIndex: initialNavIndex)
          : const OnboardingScreen(),
    );
  }
}
