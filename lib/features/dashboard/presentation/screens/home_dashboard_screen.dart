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

/// Simplified RideCare Home Dashboard Screen
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: AppSpacing.space16,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'RideCare',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                    fontSize: 20,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Asisten Kendaraan Pribadi',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (activeVehicle != null) const DashboardVehicleSelector(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFF334155)),
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: allVehicles.isEmpty || activeVehicle == null
                    ? _buildFriendlyOnboarding(context)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Hero Showcase Card (Dark Obsidian Luxury)
                          const DashboardVehicleSummaryCard(),
                          const SizedBox(height: 14),

                          // 2. Cohesive Action Deck ([Mulai Perjalanan], [Catat Servis], [Kondisi])
                          DashboardQuickActions(
                            onStartRide: onNavigateToTracking,
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
                            onNavigateToGarage: onNavigateToGarage,
                          ),
                          const SizedBox(height: 14),

                          // 3. Next Maintenance Card (Tindakan Terdekat & Biaya Realistis)
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
                          const SizedBox(height: 14),

                          // 4. Perkiraan Biaya & Anggaran Servis
                          DashboardCostBudgetCard(
                            onNavigateToMaintenance: onNavigateToMaintenance,
                          ),
                          const SizedBox(height: 14),

                          // 5. Aktivitas Bulan Ini (Bahasa Indonesia)
                          const DashboardMonthlyActivityCard(),
                          const SizedBox(height: 14),

                          // 6. Perjalanan Terakhir
                          DashboardRecentRidesCard(
                            onStartRide: onNavigateToTracking,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 3-Step Friendly Onboarding for new users (No technical jargon)
  Widget _buildFriendlyOnboarding(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space24,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              'Selamat Datang di RideCare',
              style: AppTypography.heading1.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'Asisten pribadi agar kendaraan Anda selalu aman dan terawat.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space24),

            // 3-Step Guide Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: AppSpacing.cardBorderRadius,
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildStepRow(
                    stepNumber: '1',
                    title: 'Tambah Kendaraan',
                    desc: 'Cukup masukkan jenis, merek, model, dan tahun kendaraan Anda.',
                    icon: Icons.add_circle_outline_rounded,
                  ),
                  const Divider(height: 24, color: AppColors.borderSubtle),
                  _buildStepRow(
                    stepNumber: '2',
                    title: 'RideCare Membantu Mengingat',
                    desc: 'Ketahui kapan ganti oli dan servis tanpa perlu mengingat jadwal manual.',
                    icon: Icons.notifications_none_rounded,
                  ),
                  const Divider(height: 24, color: AppColors.borderSubtle),
                  _buildStepRow(
                    stepNumber: '3',
                    title: 'Nikmati Kendaraan Lebih Terawat',
                    desc: 'Berkendara tenang setiap hari dengan perkiraan biaya yang transparan.',
                    icon: Icons.verified_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.space24),

            // Primary CTA: Tambah Kendaraan Pertama
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.buttonBorderRadius,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  'Tambah Kendaraan Pertama',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildStepRow({
    required String stepNumber,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
