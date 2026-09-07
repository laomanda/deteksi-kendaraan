import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/maintenance_price_model.dart';
import '../../domain/maintenance_cost_forecast_service.dart';
import '../../providers/maintenance_prediction_providers.dart';

class MaintenanceCostForecastCard extends ConsumerWidget {
  final String vehicleId;

  const MaintenanceCostForecastCard({
    super.key,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(maintenanceBudgetForecastProvider(vehicleId));

    return forecastAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (horizons) {
        final h30 = horizons[30];
        final h90 = horizons[90];
        final h180 = horizons[180];

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
                      Text('ESTIMATED UPCOMING COST', style: AppTypography.captionBadge),
                    ],
                  ),
                  InkWell(
                    onTap: () => _showForecastModal(context, horizons),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Forecast',
                          style: AppTypography.captionBadge.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 12),

              // Horizons Row
              Row(
                children: [
                  Expanded(
                    child: _buildHorizonBox(
                      title: 'Next 30 Days',
                      range: h30?.formattedCompactRange ?? 'Rp0',
                      count: h30?.items.length ?? 0,
                      isHighlighted: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHorizonBox(
                      title: 'Next 90 Days',
                      range: h90?.formattedCompactRange ?? 'Rp0',
                      count: h90?.items.length ?? 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHorizonBox(
                      title: 'Next 180 Days',
                      range: h180?.formattedCompactRange ?? 'Rp0',
                      count: h180?.items.length ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Estimasi biaya suku cadang & jasa berdasarkan interval perawatan kendaraan.',
                style: AppTypography.captionSubtle.copyWith(fontSize: 11),
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
    required int count,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primaryBlue.withValues(alpha: 0.06)
            : AppColors.surfaceSubtle,
        borderRadius: AppSpacing.chipBorderRadius,
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
            style: AppTypography.captionBadge.copyWith(
              fontSize: 10,
              color: isHighlighted ? AppColors.primaryBlue : AppColors.textSecondary,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            range,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isHighlighted ? AppColors.primaryBlue : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            count > 0 ? '$count komponen' : 'Tidak ada servis',
            style: AppTypography.captionSubtle.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showForecastModal(
    BuildContext context,
    Map<int, BudgetForecastHorizon> horizons,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppSpacing.modalTopRadius,
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space24,
          AppSpacing.space16,
          AppSpacing.space24,
          AppSpacing.space24,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Maintenance Budget Forecast',
                style: AppTypography.heading1.copyWith(fontSize: 20),
              ),
              Text(
                'Perkiraan anggaran servis berdasarkan jadwal jatuh tempo.',
                style: AppTypography.captionSubtle,
              ),
              const SizedBox(height: 20),
              ...[30, 90, 180].map((days) {
                final h = horizons[days];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: AppSpacing.cardBorderRadius,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              h?.title ?? 'Next $days Days',
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              h?.formattedRange ?? 'Rp0',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (h == null || h.items.isEmpty)
                          Text(
                            'Belum ada maintenance yang diperkirakan dalam periode ini.',
                            style: AppTypography.captionSubtle.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          ...h.items.map((it) => Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('• ${it.componentName}',
                                        style: AppTypography.bodySmall),
                                    Text(it.formattedCompactRange,
                                        style: AppTypography.captionBadge),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                MaintenancePriceModel.priceDisclaimer,
                style: AppTypography.captionSubtle.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.buttonBorderRadius,
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
