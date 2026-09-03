import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/controllers/maintenance_status_controller.dart';
import '../../../maintenance/presentation/widgets/maintenance_card.dart';
import '../../../ride_tracking/presentation/controllers/ride_tracking_controller.dart';
import '../../../ride_tracking/presentation/widgets/ride_summary_card.dart';
import '../../../ride_tracking/presentation/widgets/start_ride_button.dart';
import '../widgets/vehicle_header_card.dart';

/// Layar 1: Home Dashboard Screen (DSS Section 9.1 & PRD Section 6)
class HomeDashboardScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToTracking;
  final VoidCallback? onNavigateToMaintenance;

  const HomeDashboardScreen({
    super.key,
    this.onNavigateToTracking,
    this.onNavigateToMaintenance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final maintenanceStateAsync = ref.watch(maintenanceStatusProvider);
    final recentRide = ref.watch(recentRideProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo Pengendara', style: AppTypography.heading2),
            if (activeVehicle != null)
              Text(
                activeVehicle.displayName,
                style: AppTypography.captionSubtle.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          // Offline database status indicator (DSS Section 9.1)
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.space16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: AppSpacing.chipBorderRadius,
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.healthOptimal,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Offline DB',
                  style: AppTypography.captionBadge.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Vehicle Header Card
              const VehicleHeaderCard(),
              const SizedBox(height: AppSpacing.space16),

              // 2. Quick Launch: Start Ride Button
              StartRideButton(
                onStart: () {
                  onNavigateToTracking?.call();
                },
              ),
              const SizedBox(height: AppSpacing.space24),

              // 3. Maintenance Priority Section (Top 2 components needing attention)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Prioritas Perawatan', style: AppTypography.heading2),
                  if (onNavigateToMaintenance != null)
                    TextButton(
                      onPressed: onNavigateToMaintenance,
                      child: Text(
                        'Lihat Semua',
                        style: AppTypography.captionBadge.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),

              maintenanceStateAsync.when(
                data: (state) {
                  if (state.priorityComponents.isEmpty || activeVehicle == null) {
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: AppSpacing.cardBorderRadius,
                        border: AppSpacing.cardBorder,
                      ),
                      child: Center(
                        child: Text(
                          'Semua komponen dalam kondisi optimal.',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: state.priorityComponents.map((result) {
                      return MaintenanceCard(
                        result: result,
                        vehicle: activeVehicle,
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.space16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (err, _) => Text('Error: $err'),
              ),
              const SizedBox(height: AppSpacing.space24),

              // 4. Recent Ride Snapshot
              Text('Perjalanan Terakhir', style: AppTypography.heading2),
              const SizedBox(height: AppSpacing.space8),
              if (recentRide != null && activeVehicle != null)
                RideSummaryCard(
                  session: recentRide,
                  vehicleName: activeVehicle.displayName,
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: AppSpacing.cardBorderRadius,
                    border: AppSpacing.cardBorder,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          size: 36,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: AppSpacing.space8),
                        Text(
                          'Belum ada riwayat perjalanan',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mulai perjalanan sekarang untuk mencatat rute dan jarak tempuh otomatis.',
                          style: AppTypography.captionSubtle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.space32),
            ],
          ),
        ),
      ),
    );
  }
}
