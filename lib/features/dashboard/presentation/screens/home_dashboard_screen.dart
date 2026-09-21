import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/pages/maintenance_page.dart';
import '../../../maintenance/providers/maintenance_intelligence_providers.dart';
import '../../../maintenance/providers/maintenance_prediction_providers.dart';
import '../../../ride_tracking/presentation/controllers/ride_tracking_controller.dart';
import '../../../ride_tracking/presentation/screens/ride_history_screen.dart';
import '../../../vehicle/presentation/pages/add_vehicle_page.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_monthly_activity_card.dart';
import '../widgets/dashboard_next_maintenance_card.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_vehicle_selector.dart';
import '../widgets/dashboard_vehicle_summary_card.dart';

/// RideCare Home Dashboard Screen
/// Personal Vehicle Companion - Single Source of Truth: DESIGN.md
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RideCare',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                    fontSize: 21,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Asisten Kendaraan Pribadi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.secondarySteel,
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
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedClock01,
              color: AppColors.primaryNavy,
              size: 20,
            ),
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
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryNavy,
          backgroundColor: AppColors.surfaceWhite,
          onRefresh: () async {
            ref.invalidate(activeVehicleProvider);
            if (activeVehicle != null) {
              ref.invalidate(maintenanceHealthProvider(activeVehicle.id));
              ref.invalidate(upcomingMaintenanceProvider(activeVehicle.id));
            }
            ref.invalidate(rideHistoryListProvider);
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(monthlyRideStatsProvider);
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: allVehicles.isEmpty || activeVehicle == null
                    ? _buildFriendlyOnboarding(context)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Hero Vehicle Experience (Siluet, Odometer Space Grotesk, Human Status)
                          const DashboardVehicleSummaryCard(),
                          const SizedBox(height: 14),

                          // 2. Cockpit Quick Action Area (Mulai Perjalanan, Catat Servis, Cek Kendaraan)
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

                          // 3. Recommended Action / Warning Experience (Perawatan Terdekat)
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

                          // 4. Ringkasan Perjalanan & Aktivitas (Humanized Empty State & Telemetry)
                          DashboardMonthlyActivityCard(
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

  /// 3-Step Friendly Companion Onboarding for new users
  Widget _buildFriendlyOnboarding(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/illustrations/empty_garage.svg',
              width: 200,
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              'Selamat Datang di RideCare',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Asisten pribadi agar kendaraan Anda selalu aman dan terawat.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.secondarySteel,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 3-Step Guide Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06102A43),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildStepRow(
                    stepNumber: '1',
                    title: 'Tambah Kendaraan',
                    desc: 'Masukkan data jenis, merek, model, dan tahun kendaraan Anda.',
                    icon: HugeIcons.strokeRoundedAddCircle,
                  ),
                  const Divider(height: 24, color: Color(0xFFF1EFE9)),
                  _buildStepRow(
                    stepNumber: '2',
                    title: 'RideCare Membantu Mengingat',
                    desc: 'Ketahui kapan ganti oli dan servis tanpa perlu mengingat jadwal manual.',
                    icon: HugeIcons.strokeRoundedNotification01,
                  ),
                  const Divider(height: 24, color: Color(0xFFF1EFE9)),
                  _buildStepRow(
                    stepNumber: '3',
                    title: 'Nikmati Kendaraan Lebih Terawat',
                    desc: 'Berkendara tenang setiap hari dengan perkiraan servis yang jelas.',
                    icon: HugeIcons.strokeRoundedShield01,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Primary CTA: Tambah Kendaraan Pertama
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: Text(
                  'Tambah Kendaraan Pertama',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
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
    required dynamic icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.secondarySteel,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
