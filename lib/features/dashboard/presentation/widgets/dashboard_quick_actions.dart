import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/pages/add_service_page.dart';
import '../../../vehicle/presentation/pages/add_vehicle_page.dart';
import '../../../vehicle/presentation/pages/garage_page.dart';

/// Quick Actions Row/Grid on Dashboard
class DashboardQuickActions extends ConsumerWidget {
  final VoidCallback? onStartRide;
  final VoidCallback? onNavigateToGarage;

  const DashboardQuickActions({
    super.key,
    this.onStartRide,
    this.onNavigateToGarage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Action: Large Start Ride Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.buttonBorderRadius,
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text(
              'Start Ride',
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

        // 3 Secondary Quick Action Buttons
        Row(
          children: [
            // 1. Add Service
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.build_outlined,
                label: 'Add Service',
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
            const SizedBox(width: AppSpacing.space8),
            // 2. View Garage
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.garage_outlined,
                label: 'View Garage',
                onTap: () {
                  if (onNavigateToGarage != null) {
                    onNavigateToGarage!();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GaragePage(),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            // 3. + Add Vehicle
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.add_circle_outline_rounded,
                label: '+ Vehicle',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddVehiclePage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.primaryBlue),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.captionBadge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
