import 'package:flutter/material.dart';
import '../screens/maintenance_screen.dart';

/// Halaman Utama Kesehatan Kendaraan (MaintenancePage)
/// Meneruskan ke MaintenanceScreen dengan DynamicFillIcon dan layout yang konsisten
class MaintenancePage extends StatelessWidget {
  final String? initialVehicleId;

  const MaintenancePage({
    super.key,
    this.initialVehicleId,
  });

  @override
  Widget build(BuildContext context) {
    return MaintenanceScreen(initialVehicleId: initialVehicleId);
  }
}
