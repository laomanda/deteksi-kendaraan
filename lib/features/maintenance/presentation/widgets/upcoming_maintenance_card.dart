import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/maintenance_prediction_service.dart';
import '../../providers/maintenance_prediction_providers.dart';
import 'maintenance_detail_bottom_sheet.dart';

class UpcomingMaintenanceCard extends ConsumerWidget {
  final String vehicleId;

  const UpcomingMaintenanceCard({
    super.key,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingMaintenanceProvider(vehicleId));

    return upcomingAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: AppSpacing.cardBorderRadius,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.healthOptimal, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Semua komponen dalam kondisi prima. Belum ada jadwal servis mendesak.',
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            ),
          );
        }

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
                        Icons.schedule_rounded,
                        size: 18,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text('PERKIRAAN SERVIS TERDEKAT', style: AppTypography.captionBadge),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.chipBorderRadius,
                    ),
                    child: Text(
                      '${items.length} Komponen',
                      style: AppTypography.captionBadge.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 16, color: AppColors.borderSubtle),
                itemBuilder: (context, index) {
                  final p = items[index];
                  return _buildItemRow(context, p);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemRow(BuildContext context, MaintenancePrediction p) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (p.isOverdue) {
      statusColor = AppColors.healthCritical;
      statusIcon = Icons.error_rounded;
      statusLabel = 'LEWAT JADWAL';
    } else if (p.isDueSoon) {
      statusColor = AppColors.healthWarning;
      statusIcon = Icons.warning_rounded;
      statusLabel = 'SEGERA DIGANTI';
    } else {
      statusColor = AppColors.healthOptimal;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'KONDISI BAIK';
    }

    return InkWell(
      onTap: () {
        MaintenanceDetailBottomSheet.show(
          context,
          prediction: p,
          vehicleId: vehicleId,
        );
      },
      borderRadius: AppSpacing.cardBorderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.componentName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.chipBorderRadius,
                        ),
                        child: Text(
                          statusLabel,
                          style: AppTypography.captionBadge.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.isOverdue
                        ? 'Sudah melewati batas jadwal servis'
                        : 'Perkiraan: ${DateFormatter.formatKm(p.remainingKm.toDouble())} KM lagi (${p.remainingDays > 0 ? '${p.remainingDays} hari' : 'segera'})',
                    style: AppTypography.bodySmall.copyWith(
                      color: p.isOverdue ? AppColors.healthCritical : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Biaya: ${p.formattedCompactRange}',
                        style: AppTypography.captionBadge.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Lihat Detail',
                            style: AppTypography.captionBadge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
