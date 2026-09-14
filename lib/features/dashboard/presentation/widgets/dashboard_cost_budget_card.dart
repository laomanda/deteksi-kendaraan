import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/presentation/pages/maintenance_page.dart';
import '../../../maintenance/providers/maintenance_prediction_providers.dart';

/// Card presenting Estimated Upcoming Cost & Maintenance Budget Forecast
/// Clean, harmonious financial card without arbitrary highlights
class DashboardCostBudgetCard extends ConsumerWidget {
  final VoidCallback? onNavigateToMaintenance;

  const DashboardCostBudgetCard({
    super.key,
    this.onNavigateToMaintenance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    if (activeVehicle == null) {
      return const SizedBox.shrink();
    }

    final forecastAsync = ref.watch(maintenanceBudgetForecastProvider(activeVehicle.id));

    return forecastAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (forecastMap) {
        final f30 = forecastMap[30];
        final f90 = forecastMap[90];
        final f180 = forecastMap[180];

        final hasAnyCost = (f30 != null && f30.hasItems) ||
            (f90 != null && f90.hasItems) ||
            (f180 != null && f180.hasItems);

        return Container(
          padding: const EdgeInsets.all(AppSpacing.space16),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Perkiraan Pengeluaran Servis',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      if (onNavigateToMaintenance != null) {
                        onNavigateToMaintenance!();
                      } else {
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
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'Rincian',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (!hasAnyCost)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimasi biaya belum tersedia untuk jadwal saat ini.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // 3-Column Horizon Grid - Harmonious balanced neutral style
                Row(
                  children: [
                    Expanded(
                      child: _buildHorizonBox(
                        title: '30 Hari',
                        sublabel: 'Jangka Dekat',
                        range: f30?.hasItems == true
                            ? f30!.formattedCompactRange
                            : 'Rp0',
                        itemCount: f30?.items.length ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHorizonBox(
                        title: '90 Hari',
                        sublabel: '3 Bulan',
                        range: f90?.hasItems == true
                            ? f90!.formattedCompactRange
                            : 'Rp0',
                        itemCount: f90?.items.length ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHorizonBox(
                        title: '180 Hari',
                        sublabel: '6 Bulan',
                        range: f180?.hasItems == true
                            ? f180!.formattedCompactRange
                            : 'Rp0',
                        itemCount: f180?.items.length ?? 0,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              // Disclaimer in clean muted text
              const Text(
                'Estimasi harga mencakup suku cadang & jasa rata-rata bengkel umum.',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizonBox({
    required String title,
    required String sublabel,
    required String range,
    required int itemCount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            range,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$itemCount komponen',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
