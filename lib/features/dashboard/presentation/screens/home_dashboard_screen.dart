import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/pages/maintenance_page.dart';
import '../../../maintenance/providers/maintenance_intelligence_providers.dart';
import '../../../maintenance/providers/maintenance_prediction_providers.dart';
import '../../../ride_tracking/presentation/controllers/ride_tracking_controller.dart';
import '../../../ride_tracking/presentation/screens/ride_history_screen.dart';
import '../../../vehicle/presentation/pages/add_vehicle_page.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_cost_budget_card.dart';
import '../widgets/dashboard_monthly_activity_card.dart';
import '../widgets/dashboard_next_maintenance_card.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_recent_rides_card.dart';
import '../widgets/dashboard_vehicle_selector.dart';
import '../widgets/dashboard_vehicle_summary_card.dart';

/// Upgraded RideCare Home Dashboard Screen
class HomeDashboardScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToTracking;
  final VoidCallback? onNavigateToMaintenance;
  final VoidCallback? onNavigateToGarage;

  const HomeDashboardScreen({
    super.key,
    this.onNavigateToTracking,
    this.onNavigateToMaintenance,
    this.onNavigateToGarage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final allVehicles = ref.watch(vehicleListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        titleSpacing: AppSpacing.space16,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RideCare',
                  style: AppTypography.heading2.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Smart Vehicle Intelligence',
                  style: AppTypography.captionSubtle.copyWith(fontSize: 10),
                ),
              ],
            ),
            const Spacer(),
            if (activeVehicle != null) const DashboardVehicleSelector(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textPrimary),
            tooltip: 'Riwayat Perjalanan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RideHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () async {
            ref.invalidate(activeVehicleProvider);
            if (activeVehicle != null) {
              ref.invalidate(maintenanceHealthProvider(activeVehicle.id));
              ref.invalidate(upcomingMaintenanceProvider(activeVehicle.id));
              ref.invalidate(maintenanceCostForecastProvider(activeVehicle.id));
              ref.invalidate(maintenanceBudgetForecastProvider(activeVehicle.id));
            }
            ref.invalidate(rideHistoryListProvider);
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(monthlyRideStatsProvider);
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: allVehicles.isEmpty || activeVehicle == null
                ? _buildEmptyVehicleState(context)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Vehicle Status Summary Card (Visual Anchor)
                      const DashboardVehicleSummaryCard(),
                      const SizedBox(height: AppSpacing.space16),

                      // 2. Next Maintenance Card (Smart Priority: OVERDUE > DUE SOON > GOOD)
                      DashboardNextMaintenanceCard(
                        onNavigateToMaintenance: onNavigateToMaintenance ??
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MaintenancePage(
                                    initialVehicleId: activeVehicle.id,
                                  ),
                                ),
                              );
                            },
                      ),
                      const SizedBox(height: AppSpacing.space16),

                      // 3. Quick Actions
                      DashboardQuickActions(
                        onStartRide: onNavigateToTracking,
                        onNavigateToGarage: onNavigateToGarage,
                      ),
                      const SizedBox(height: AppSpacing.space24),

                      // 4. Upcoming Cost & Budget Forecast
                      DashboardCostBudgetCard(
                        onNavigateToMaintenance: onNavigateToMaintenance,
                      ),
                      const SizedBox(height: AppSpacing.space16),

                      // 5. Monthly Activity Snapshot
                      const DashboardMonthlyActivityCard(),
                      const SizedBox(height: AppSpacing.space16),

                      // 6. Recent Rides (Max 3 latest rides)
                      DashboardRecentRidesCard(
                        onStartRide: onNavigateToTracking,
                      ),
                      const SizedBox(height: AppSpacing.space24),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Empty state when no vehicles are registered
  Widget _buildEmptyVehicleState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space24,
        vertical: AppSpacing.space48,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                size: 44,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            Text(
              'Belum Ada Kendaraan',
              style: AppTypography.heading1.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'Mulai dengan menambahkan kendaraan pertama Anda untuk memantau kesehatan dan perawatan berkala.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.buttonBorderRadius,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Tambah Kendaraan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
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
      ),
    );
  }
}
