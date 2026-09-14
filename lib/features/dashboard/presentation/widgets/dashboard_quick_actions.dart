import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/pages/add_service_page.dart';
import '../../../maintenance/presentation/pages/maintenance_page.dart';

/// Cohesive Action Deck with Unified Brand Palette (No clashing colors)
class DashboardQuickActions extends ConsumerWidget {
  final VoidCallback? onStartRide;
  final VoidCallback? onNavigateToMaintenance;
  final VoidCallback? onNavigateToGarage;

  const DashboardQuickActions({
    super.key,
    this.onStartRide,
    this.onNavigateToMaintenance,
    this.onNavigateToGarage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Primary Action: Mulai Perjalanan (Clean Royal Blue)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onStartRide,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded, size: 22, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Mulai Perjalanan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 2 & 3: Companion Cards ([Catat Servis] & [Kondisi Komponen])
        Row(
          children: [
            // Catat Servis
            Expanded(
              child: _buildActionTile(
                context: context,
                icon: Icons.build_circle_outlined,
                title: 'Catat Servis',
                subtitle: 'Riwayat perawatan',
                onTap: () {
                  if (activeVehicle == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pilih kendaraan terlebih dahulu.'),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddServicePage(vehicle: activeVehicle),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            // Kondisi Komponen
            Expanded(
              child: _buildActionTile(
                context: context,
                icon: Icons.health_and_safety_outlined,
                title: 'Kondisi Komponen',
                subtitle: 'Cek status mesin',
                onTap: () {
                  if (onNavigateToMaintenance != null) {
                    onNavigateToMaintenance!();
                  } else if (activeVehicle != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MaintenancePage(
                          initialVehicleId: activeVehicle.id,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // Soft clean blue
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
