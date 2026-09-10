import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/pages/add_service_page.dart';
import '../../../maintenance/presentation/pages/maintenance_page.dart';

/// Simplified Quick Actions for RideCare Dashboard
/// Gives user 3 unambiguous choices:
/// 1. [Mulai Perjalanan]
/// 2. [Catat Servis]
/// 3. [Lihat Kondisi]
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
        // 1. Aksi Utama: Mulai Perjalanan
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.buttonBorderRadius,
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text(
              'Mulai Perjalanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            onPressed: onStartRide,
          ),
        ),

        const SizedBox(height: AppSpacing.space12),

        // 2 & 3: [Catat Servis] dan [Lihat Kondisi]
        Row(
          children: [
            // Catat Servis
            Expanded(
              child: _buildSecondaryButton(
                context: context,
                icon: Icons.build_circle_outlined,
                label: 'Catat Servis',
                onTap: () {
                  if (activeVehicle == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pilih atau tambahkan kendaraan terlebih dahulu.'),
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
            const SizedBox(width: AppSpacing.space12),
            // Lihat Kondisi
            Expanded(
              child: _buildSecondaryButton(
                context: context,
                icon: Icons.health_and_safety_outlined,
                label: 'Lihat Kondisi',
                onTap: () {
                  if (onNavigateToMaintenance != null) {
                    onNavigateToMaintenance!();
                  } else if (activeVehicle != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MaintenancePage(initialVehicleId: activeVehicle.id),
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

  Widget _buildSecondaryButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
