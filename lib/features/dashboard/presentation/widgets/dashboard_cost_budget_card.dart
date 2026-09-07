import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../garage/presentation/controllers/active_vehicle_controller.dart';
import '../../../maintenance/data/models/maintenance_price_model.dart';
import '../../../maintenance/presentation/pages/maintenance_page.dart';
import '../../../maintenance/providers/maintenance_prediction_providers.dart';

/// Card presenting Estimated Upcoming Cost & Maintenance Budget Forecast
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
            borderRadius: AppSpacing.cardBorderRadius,
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ESTIMATED UPCOMING COST',
                        style: AppTypography.captionBadge.copyWith(
                          color: AppColors.primaryBlue,
                          letterSpacing: 0.5,
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
                    child: Text(
                      'Rincian',
                      style: AppTypography.captionBadge.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.space12),

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
                // 3-Column Horizon Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildHorizonBox(
                        title: 'Next 30 Days',
                        range: f30?.hasItems == true
                            ? f30!.formattedCompactRange
                            : 'Rp0',
                        itemCount: f30?.items.length ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHorizonBox(
                        title: 'Next 90 Days',
                        range: f90?.hasItems == true
                            ? f90!.formattedCompactRange
                            : 'Rp0',
                        itemCount: f90?.items.length ?? 0,
                        isHighlighted: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHorizonBox(
                        title: 'Next 180 Days',
                        range: f180?.hasItems == true
                            ? f180!.formattedCompactRange
                            : 'Rp0',
                        itemCount: f180?.items.length ?? 0,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),
              // Disclaimer note
              Text(
                MaintenancePriceModel.priceDisclaimer,
                style: AppTypography.captionSubtle.copyWith(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  height: 1.3,
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
    required String range,
    required int itemCount,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primaryBlue.withValues(alpha: 0.05)
            : AppColors.bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted
              ? AppColors.primaryBlue.withValues(alpha: 0.3)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.captionSubtle.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            range,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: isHighlighted
                  ? AppColors.primaryBlue
                  : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$itemCount servis',
            style: AppTypography.captionSubtle.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
